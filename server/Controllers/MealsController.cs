using Microsoft.AspNetCore.Mvc;
using ZestAPI.Models;
using ZestAPI.Data;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MealsController(ZestDbContext context, IServiceScopeFactory scopeFactory) : ControllerBase
{
    private readonly ZestDbContext _context = context;
    private readonly IServiceScopeFactory _scopeFactory = scopeFactory;

    private static string? _huSessionCookie;
    private static string? _enSessionCookie;

    private static async Task<string> GetFreshSessionCookie(string baseUrl)
    {
        try
        {
            var handler = new HttpClientHandler { AllowAutoRedirect = false };
            using var client = new HttpClient(handler);
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

            var response = await client.GetAsync(baseUrl);

            if (response.Headers.TryGetValues("Set-Cookie", out var cookies))
            {
                foreach (var cookie in cookies)
                {
                    var match = Regex.Match(cookie, @"myPHP83SESSID=([^;]+)");
                    if (match.Success)
                    {
                        var sessionId = match.Groups[1].Value;
                        Console.WriteLine($"[MealsController] Új session ID szerezve innen: {baseUrl} -> {sessionId}");
                        return $"myPHP83SESSID={sessionId}";
                    }
                }
            }
            Console.WriteLine($"[MealsController] Nem sikerült sütit szerezni innen: {baseUrl}");
            return "";
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[MealsController] Hiba a süti lekérésekor: {ex.Message}");
            return "";
        }
    }

    private static async Task ForceLanguage(string baseUrl, string lang, string cookie)
    {
        if (string.IsNullOrEmpty(cookie)) return;

        try
        {
            var handler = new HttpClientHandler { AllowAutoRedirect = false };
            using var client = new HttpClient(handler);
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

            var url = $"{baseUrl}/log_lang.php?lang={lang}";
            var request = new HttpRequestMessage(HttpMethod.Get, url);

            request.Headers.Add("Cookie", $"{cookie}; kb_lang={lang}");

            await client.SendAsync(request);
            Console.WriteLine($"[MealsController] Nyelv kényszerítve ({lang}) a sütihez: {cookie}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Nyelvváltási hiba: {ex.Message}");
        }
    }

    private static async Task<string> GetValidCookieForLang(string lang)
    {
        if (lang == "hu")
        {
            if (string.IsNullOrEmpty(_huSessionCookie))
            {
                _huSessionCookie = await GetFreshSessionCookie("https://kaloriabazis.hu");
                await ForceLanguage("https://kaloriabazis.hu", "hu", _huSessionCookie);
            }
            return _huSessionCookie;
        }
        else
        {
            if (string.IsNullOrEmpty(_enSessionCookie))
            {
                _enSessionCookie = await GetFreshSessionCookie("https://caloriebase.com");
                await ForceLanguage("https://caloriebase.com", "en", _enSessionCookie);
            }
            return _enSessionCookie;
        }
    }

    [HttpGet("husearch")]
    public async Task<IActionResult> HUSearch([FromQuery] string q)
    {
        return await SearchFood(q, "hu", "https://kaloriabazis.hu/getfood.php");
    }

    [HttpGet("ensearch")]
    public async Task<IActionResult> ENSearch([FromQuery] string q)
    {
        return await SearchFood(q, "en", "https://caloriebase.com/getfood.php");
    }

    private async Task<IActionResult> SearchFood(string q, string lang, string externalApiUrl)
    {
        if (string.IsNullOrWhiteSpace(q)) return Ok(new List<object>());

        var qLower = q.ToLower().Trim();

        var localResults = await _context.FoodItems
            .Where(f => f.Name.ToLower().Contains(qLower) && f.Language == lang)
            .Take(15)
            .ToListAsync();

        if (localResults.Count > 2)
        {
            return Ok(MapToFrontendDto(localResults));
        }

        try
        {
            var cookie = await GetValidCookieForLang(lang);
            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
            client.DefaultRequestHeaders.Add("Accept-Language", lang == "hu" ? "hu-HU,hu;q=0.9" : "en-US,en;q=0.9");

            var uri = new UriBuilder(externalApiUrl);
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["q"] = q;
            query["p"] = "1";
            query["s"] = "8";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", $"{cookie}; kb_lang={lang}");
            request.Headers.Add("X-Requested-With", "XMLHttpRequest");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return Ok(MapToFrontendDto(localResults));

            var newItems = await ParseAndSaveExternalData(content, lang);

            localResults.AddRange(newItems);

            var distinctResults = localResults.GroupBy(x => x.ExternalId).Select(g => g.First()).ToList();
            return Ok(MapToFrontendDto(distinctResults));
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Hiba az adathalászat során: {ex.Message}");
            return Ok(MapToFrontendDto(localResults));
        }
    }

    private async Task<List<FoodItem>> ParseAndSaveExternalData(string jsonContent, string lang)
    {
        var newItems = new List<FoodItem>();
        try
        {
            using var jsonDoc = JsonDocument.Parse(jsonContent);
            var root = jsonDoc.RootElement;

            JsonElement itemsArray = root;
            if (root.ValueKind == JsonValueKind.Object)
            {
                if (root.TryGetProperty("results2", out var r2)) itemsArray = r2;
                else if (root.TryGetProperty("results", out var r)) itemsArray = r;
                else if (root.TryGetProperty("data", out var d)) itemsArray = d;
                else if (root.TryGetProperty("food_list", out var fl)) itemsArray = fl;
            }

            if (itemsArray.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in itemsArray.EnumerateArray())
                {
                    string extId = GetStringValue(item, "foodId", "food_id", "id", "obj_id");
                    string rawName = GetStringValue(item, "name", "title");
                    string name = StripHtmlTags(rawName);

                    if (!string.IsNullOrEmpty(extId) && !string.IsNullOrEmpty(name))
                    {
                        bool exists = await _context.FoodItems.AnyAsync(f => f.ExternalId == extId && f.Language == lang);
                        if (!exists)
                        {
                            var food = new FoodItem
                            {
                                ExternalId = extId,
                                Name = name,
                                Calories = GetDoubleValue(item, "calories", "cal", "kcal_and_unit"),
                                Protein = GetDoubleValue(item, "protein", "proteins"),
                                Carbs = GetDoubleValue(item, "carbo", "carbs", "carbohydrate"),
                                Fat = GetDoubleValue(item, "fat", "fats"),
                                Unit = GetStringValue(item, "unit", "piece"),
                                Language = lang
                            };

                            _context.FoodItems.Add(food);
                            newItems.Add(food);

                            var defaultUnit = new FoodUnit
                            {
                                FoodExternalId = extId,
                                Name = "UNIT_g",
                                Weight = 1,
                                Language = lang
                            };
                            _context.FoodUnits.Add(defaultUnit);
                        }
                    }
                }

                if (newItems.Count > 0)
                {
                    await _context.SaveChangesAsync();

                    _ = Task.Run(async () => await FetchAndSaveUnitsForFoodsInBackground(newItems, lang));
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Hiba a feldolgozáskor: {ex.Message}");
        }

        return newItems;
    }

    private async Task FetchAndSaveUnitsForFoodsInBackground(List<FoodItem> foods, string lang)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

            string cookie = await GetValidCookieForLang(lang);
            string baseUrl = lang == "hu" ? "https://kaloriabazis.hu" : "https://caloriebase.com";

            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
            client.DefaultRequestHeaders.Add("Accept-Language", lang == "hu" ? "hu-HU,hu;q=0.9" : "en-US,en;q=0.9");

            foreach (var food in foods)
            {
                await Task.Delay(500);

                var uri = new UriBuilder($"{baseUrl}/food.php");
                var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
                query["show"] = "getmenew";
                query["id"] = food.ExternalId;
                query["food_id_directly"] = "1";
                uri.Query = query.ToString();

                var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
                request.Headers.Add("Cookie", $"{cookie}; kb_lang={lang}");

                var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode) continue;

                var content = await response.Content.ReadAsStringAsync();
                if (content.TrimStart().StartsWith("<")) continue;

                using var jsonDoc = JsonDocument.Parse(content);
                var root = jsonDoc.RootElement;
                JsonElement itemsArray = root;

                if (root.TryGetProperty("getme", out var getmeElement)) itemsArray = getmeElement;

                if (itemsArray.ValueKind == JsonValueKind.Array)
                {
                    var newUnits = new List<FoodUnit>();
                    foreach (var item in itemsArray.EnumerateArray())
                    {
                        string unitName = GetStringValue(item, "Name");
                        double weight = GetDoubleValue(item, "nWeight");

                        if (!string.IsNullOrEmpty(unitName))
                        {
                            bool exists = await dbContext.FoodUnits.AnyAsync(u =>
                                u.FoodExternalId == food.ExternalId &&
                                u.Name == unitName &&
                                u.Language == lang);

                            if (!exists)
                            {
                                newUnits.Add(new FoodUnit
                                {
                                    FoodExternalId = food.ExternalId,
                                    Name = unitName,
                                    Weight = weight,
                                    Language = lang
                                });
                            }
                        }
                    }

                    if (newUnits.Any())
                    {
                        dbContext.FoodUnits.AddRange(newUnits);
                        await dbContext.SaveChangesAsync();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Háttérfolyamat hiba a mértékegységek letöltésekor: {ex.Message}");
        }
    }

    private List<object> MapToFrontendDto(List<FoodItem> items)
    {
        return items.Select(i => new
        {
            foodId = i.ExternalId,
            name = i.Name,
            calories = i.Calories,
            protein = i.Protein,
            carbs = i.Carbs,
            fat = i.Fat,
            unit = i.Unit
        }).Cast<object>().ToList();
    }

    [HttpGet("hu-get-units")]
    public async Task<IActionResult> HUGetUnits([FromQuery] string foodId)
    {
        var cookie = await GetValidCookieForLang("hu");
        return await GetUnitsInternal("https://kaloriabazis.hu", foodId, cookie, "hu");
    }

    [HttpGet("en-get-units")]
    public async Task<IActionResult> ENGetUnits([FromQuery] string foodId)
    {
        var cookie = await GetValidCookieForLang("en");
        return await GetUnitsInternal("https://caloriebase.com", foodId, cookie, "en");
    }

    private async Task<IActionResult> GetUnitsInternal(string baseUrl, string foodId, string cookie, string lang)
    {
        if (string.IsNullOrWhiteSpace(foodId)) return BadRequest(new { error = "foodId kötelező." });

        try
        {
            var localUnits = await _context.FoodUnits.Where(u => u.FoodExternalId == foodId && u.Language == lang).ToListAsync();
            if (localUnits.Any())
            {
                var result = localUnits.Select(u => new Dictionary<string, string>
            {
                { "Name", u.Name },
                { "nWeight", u.Weight.ToString(System.Globalization.CultureInfo.InvariantCulture) }
            }).ToList();

                return Ok(result);
            }

            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
            client.DefaultRequestHeaders.Add("Accept-Language", lang == "hu" ? "hu-HU,hu;q=0.9" : "en-US,en;q=0.9");

            var uri = new UriBuilder($"{baseUrl}/food.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["show"] = "getmenew";
            query["id"] = foodId;
            query["food_id_directly"] = "1";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", $"{cookie}; kb_lang={lang}");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode) return StatusCode((int)response.StatusCode, new { error = "API Hiba" });
            if (content.TrimStart().StartsWith("<")) return StatusCode(500, new { error = "Nem JSON válasz" });

            using var jsonDoc = JsonDocument.Parse(content);
            var root = jsonDoc.RootElement;
            JsonElement itemsArray = root;

            if (root.TryGetProperty("getme", out var getmeElement)) itemsArray = getmeElement;

            if (itemsArray.ValueKind == JsonValueKind.Array)
            {
                var newUnits = new List<FoodUnit>();
                foreach (var item in itemsArray.EnumerateArray())
                {
                    string unitName = GetStringValue(item, "Name");
                    double weight = GetDoubleValue(item, "nWeight");

                    if (!string.IsNullOrEmpty(unitName))
                    {
                        newUnits.Add(new FoodUnit
                        {
                            FoodExternalId = foodId,
                            Name = unitName,
                            Weight = weight,
                            Language = lang
                        });
                    }
                }

                if (newUnits.Any())
                {
                    _context.FoodUnits.AddRange(newUnits);
                    await _context.SaveChangesAsync();
                }

                return Ok(JsonSerializer.Deserialize<List<object>>(itemsArray.GetRawText()));
            }

            return Ok(new { raw = root });
        }
        catch (Exception ex) { return StatusCode(500, new { error = ex.Message }); }
    }

    [HttpGet("hu-get-by-barcode")]
    public async Task<IActionResult> HUGetByBarcode([FromQuery] string code)
    {
        var cookie = await GetValidCookieForLang("hu");
        return await GetByBarcodeInternal("https://kaloriabazis.hu", code, cookie, "hu");
    }

    [HttpGet("en-get-by-barcode")]
    public async Task<IActionResult> ENGetByBarcode([FromQuery] string code)
    {
        var cookie = await GetValidCookieForLang("en");
        return await GetByBarcodeInternal("https://caloriebase.com", code, cookie, "en");
    }

    private async Task<IActionResult> GetByBarcodeInternal(string baseUrl, string code, string cookie, string lang)
    {
        if (string.IsNullOrWhiteSpace(code)) return BadRequest("code kötelező.");

        var localFood = await _context.FoodItems.FirstOrDefaultAsync(f => f.Barcode == code && f.Language == lang);
        if (localFood != null)
        {
            var foodDataDict = new Dictionary<string, string>
        {
            { "nID", localFood.ExternalId },
            { "cDisplayName", localFood.Name },
            { "nCalorie", localFood.Calories.ToString(System.Globalization.CultureInfo.InvariantCulture) },
            { "nProtein", localFood.Protein.ToString(System.Globalization.CultureInfo.InvariantCulture) },
            { "nCarbo", localFood.Carbs.ToString(System.Globalization.CultureInfo.InvariantCulture) },
            { "nFat", localFood.Fat.ToString(System.Globalization.CultureInfo.InvariantCulture) }
        };

            return Ok(new Dictionary<string, object>
        {
            { "food_data", foodDataDict }
        });
        }

        try
        {
            using var client = new HttpClient();
            var uri = new UriBuilder($"{baseUrl}/barcode_ajax.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["show"] = "get_food_info_from_bcode";
            query["bcode"] = code;
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", $"{cookie}; kb_lang={lang}");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode) return StatusCode((int)response.StatusCode, "Hiba a külső API-nál.");

            using var jsonDoc = JsonDocument.Parse(content);
            var root = jsonDoc.RootElement;

            if (root.TryGetProperty("food_data", out var foodData) && foodData.ValueKind != JsonValueKind.Null)
            {
                string extId = GetStringValue(foodData, "nID");
                if (!string.IsNullOrEmpty(extId))
                {
                    var existingFood = await _context.FoodItems.FirstOrDefaultAsync(f => f.ExternalId == extId && f.Language == lang);

                    if (existingFood != null)
                    {
                        existingFood.Barcode = code;
                    }
                    else
                    {
                        var newFood = new FoodItem
                        {
                            ExternalId = extId,
                            Barcode = code,
                            Name = StripHtmlTags(GetStringValue(foodData, "cDisplayName")),
                            Calories = GetDoubleValue(foodData, "nCalorie"),
                            Protein = GetDoubleValue(foodData, "nProtein"),
                            Carbs = GetDoubleValue(foodData, "nCarbo"),
                            Fat = GetDoubleValue(foodData, "nFat"),
                            Language = lang
                        };
                        _context.FoodItems.Add(newFood);
                    }
                    await _context.SaveChangesAsync();
                }
            }

            var parsed = JsonSerializer.Deserialize<object>(content);
            return Ok(parsed);
        }
        catch (Exception ex) { return StatusCode(500, $"Szerver hiba: {ex.Message}"); }
    }

    [HttpPost("addGroup")]
    [Authorize]
    public async Task<IActionResult> AddUserMealGroup([FromBody] AddUserMealGroupRequest request)
    {
        var userId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return BadRequest("Felhasználó nem található.");

        var userMeal = new UserMeal
        {
            MealName = Enum.Parse<MealName>(request.MealName ?? ""),
            UserId = userId,
            EatenAt = request.EatenAt ?? DateTime.MinValue,
            TotalCalories = request.Meals.Sum(m => m.Calories * m.Quantity),
            TotalProtein = request.Meals.Sum(m => m.Protein * m.Quantity),
            TotalCarbs = request.Meals.Sum(m => m.Carbs * m.Quantity),
            TotalFat = request.Meals.Sum(m => m.Fat * m.Quantity),
            IsCustom = request.IsCustom,
            Meals = request.Meals.Select(m => new Meals
            {
                FoodId = m.FoodId ?? "",
                Name = m.Name ?? "",
                Piece = m.Piece,
                Calories = m.Calories,
                Proteins = m.Protein,
                Carbs = m.Carbs,
                Fat = m.Fat,
                Quantity = m.Quantity,
                BaseWeight = m.BaseWeight,
                Unit = m.Unit,
            }).ToList()
        };

        _context.UserMeals.Add(userMeal);
        await _context.SaveChangesAsync();
        Console.WriteLine($"[AddUserMealGroup] Received UserId: {request.UserId}");

        return Ok(new { Message = "Csoportos mentés sikeres", UserMealId = userMeal.Id });
    }

    [HttpPost("addGroupS")]
    [Authorize]
    public async Task<IActionResult> AddUserMealGroupS([FromBody] AddUserMealGroupRequest request)
    {
        var userId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return BadRequest("Felhasználó nem található.");

        var userMeal = new UserMeal
        {
            CustomName = request.CustomName,
            UserId = userId,
            EatenAt = request.EatenAt ?? DateTime.MinValue,
            TotalCalories = request.Meals.Sum(m => m.Calories * m.Quantity),
            TotalProtein = request.Meals.Sum(m => m.Protein * m.Quantity),
            TotalCarbs = request.Meals.Sum(m => m.Carbs * m.Quantity),
            TotalFat = request.Meals.Sum(m => m.Fat * m.Quantity),
            IsCustom = request.IsCustom,
            Meals = request.Meals.Select(m => new Meals
            {
                FoodId = m.FoodId ?? "",
                Name = m.Name ?? "",
                Piece = m.Piece,
                Calories = m.Calories,
                Proteins = m.Protein,
                Carbs = m.Carbs,
                Fat = m.Fat,
                Quantity = m.Quantity,
                BaseWeight = m.BaseWeight,
                Unit = m.Unit,
            }).ToList()
        };

        _context.UserMeals.Add(userMeal);
        await _context.SaveChangesAsync();
        Console.WriteLine($"[AddUserMealGroup] Received UserId: {request.UserId}");

        return Ok(new { Message = "Csoportos mentés sikeres", UserMealId = userMeal.Id });
    }

    [HttpGet("getUserMeals")]
    [Authorize]
    public async Task<IActionResult> GetUserMeals()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var meals = await _context.UserMeals
            .Where(m => m.UserId == userId)
            .Include(m => m.Meals)
            .OrderByDescending(m => m.EatenAt)
            .Select(m => new
            {
                m.Id,
                MealName = m.MealName.ToString(),
                m.TotalCalories,
                m.TotalProtein,
                m.TotalCarbs,
                m.TotalFat,
                m.EatenAt,
                m.IsCustom,
                Meals = m.Meals.Select(mi => new
                {
                    mi.FoodId,
                    mi.Name,
                    mi.Calories,
                    mi.Proteins,
                    mi.Carbs,
                    mi.Fat,
                    mi.Quantity,
                    mi.Unit,
                    mi.BaseWeight,
                    CalculatedCalories = mi.Calories * mi.Quantity,
                    CalculatedProtein = mi.Proteins * mi.Quantity,
                    CalculatedCarbs = mi.Carbs * mi.Quantity,
                    CalculatedFat = mi.Fat * mi.Quantity
                }).ToList()
            })
            .ToListAsync();

        Console.WriteLine($"Talált {meals.Count} étkezést a UserId={userId}-hez");

        return Ok(meals);
    }

    [HttpGet("getCustomUserMeals")]
    [Authorize]
    public async Task<IActionResult> GetCustomUserMeals()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var meals = await _context.UserMeals
            .Where(m => m.UserId == userId && m.IsCustom == true)
            .Include(m => m.Meals)
            .OrderByDescending(m => m.EatenAt)
            .Select(m => new
            {
                m.Id,
                m.CustomName,
                m.TotalCalories,
                m.TotalProtein,
                m.TotalCarbs,
                m.TotalFat,
                m.EatenAt,
                m.IsCustom,
                Meals = m.Meals.Select(mi => new
                {
                    mi.Id,
                    mi.FoodId,
                    mi.Name,
                    mi.Calories,
                    mi.Proteins,
                    mi.Carbs,
                    mi.Fat,
                    mi.Quantity,
                    mi.Unit,
                    mi.BaseWeight,
                    CalculatedCalories = mi.Calories * mi.Quantity,
                    CalculatedProtein = mi.Proteins * mi.Quantity,
                    CalculatedCarbs = mi.Carbs * mi.Quantity,
                    CalculatedFat = mi.Fat * mi.Quantity
                }).ToList()
            })
            .ToListAsync();

        Console.WriteLine($"Talált {meals.Count} étkezést a UserId={userId}-hez");

        return Ok(meals);
    }

    [HttpGet("getTodayCalories")]
    [Authorize]
    public async Task<IActionResult> GetTodayCalories()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var utcToday = DateTime.UtcNow.Date;
        var utcTomorrow = utcToday.AddDays(1);

        var totalcalories = await _context.UserMeals
            .Where(m => m.UserId == userId && m.EatenAt >= utcToday && m.EatenAt < utcTomorrow)
            .SumAsync(t => t.TotalCalories);

        return Ok(totalcalories);
    }

    [HttpGet("getTodayNutrients")]
    [Authorize]
    public async Task<IActionResult> GetTodayNutrients()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var utcToday = DateTime.UtcNow.Date;
        var utcTomorrow = utcToday.AddDays(1);

        var totalcalories = await _context.UserMeals
            .Where(m => m.UserId == userId && m.EatenAt >= utcToday && m.EatenAt < utcTomorrow)
            .SumAsync(t => t.TotalCalories);

        var totalcarbs = await _context.UserMeals
            .Where(m => m.UserId == userId && m.EatenAt >= utcToday && m.EatenAt < utcTomorrow)
            .SumAsync(t => t.TotalCarbs);

        var totalfat = await _context.UserMeals
            .Where(m => m.UserId == userId && m.EatenAt >= utcToday && m.EatenAt < utcTomorrow)
            .SumAsync(t => t.TotalFat);

        var totalprotein = await _context.UserMeals
            .Where(m => m.UserId == userId && m.EatenAt >= utcToday && m.EatenAt < utcTomorrow)
            .SumAsync(t => t.TotalProtein);

        return Ok(new { totalcalories, totalcarbs, totalfat, totalprotein });
    }

    [HttpDelete("deleteUserMeal/{id}")]
    [Authorize]
    public async Task<IActionResult> DeleteUserMeal(int id)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null)
            return Unauthorized();

        var meal = await _context.UserMeals.FindAsync(id);
        if (meal == null)
            return NotFound();

        _context.UserMeals.Remove(meal);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("DeleteCustomMeal")]
    [Authorize]
    public async Task<IActionResult> DeleteCustomMeal([FromQuery] int id)
    {
        var meal = await _context.Meals.FindAsync(id);

        if (meal == null)
            return NotFound("Nincs ilyen étel a custom sablonban");

        _context.Meals.Remove(meal);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Étel törlés sikeres" });
    }

    [HttpDelete("DeleteTemplate")]
    [Authorize]
    public async Task<IActionResult> DeleteTemplate([FromQuery] int id)
    {
        var meal = await _context.UserMeals
            .Include(m => m.Meals)
            .FirstOrDefaultAsync(m => m.Id == id);

        if (meal == null)
            return NotFound("Nincs ilyen étkezés");

        var userIdClaim = User.FindFirst("id")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (userIdClaim == null)
            return Unauthorized("Nincs érvényes azonosító a tokenben.");

        var userId = int.Parse(userIdClaim);

        if (meal.UserId != userId)
            return Unauthorized("Nincs jogosultsága törölni ezt a sablont.");

        _context.UserMeals.Remove(meal);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Étkezés törlés sikeres" });
    }

    [HttpPost("AddFoodToTemplate")]
    public async Task<IActionResult> AddFoodToTemplate([FromBody] AddFoodToTemplateDto dto)
    {
        var template = await _context.UserMeals
            .Include(x => x.Meals)
            .FirstOrDefaultAsync(x => x.Id == dto.TemplateId && x.UserId == dto.UserId);

        if (template == null)
            return NotFound("Nincs ilyen sablonod.");

        var newMeal = new Meals
        {
            UserMealId = template.Id,
            FoodId = dto.FoodId ?? "",
            Name = dto.Name ?? "",
            Quantity = dto.Quantity,
            Calories = dto.Calories,
            Proteins = dto.Protein,
            Carbs = dto.Carbs,
            Fat = dto.Fat,
            Unit = dto.Unit,
            BaseWeight = dto.BaseWeight
        };

        template.Meals.Add(newMeal);
        await _context.SaveChangesAsync();

        return Ok(new { id = newMeal.Id });
    }

    [HttpGet("getFriendCustomMeals/{friendId}")]
    [Authorize]
    public async Task<IActionResult> GetFriendCustomMeals(int friendId)
    {
        var currentUserIdClaim = User.FindFirst("id")?.Value;
        if (currentUserIdClaim == null) return Unauthorized();
        var currentUserId = int.Parse(currentUserIdClaim);

        var isFriend = await _context.Friendships.AnyAsync(f =>
            ((f.RequesterId == currentUserId && f.AddresseeId == friendId) ||
             (f.RequesterId == friendId && f.AddresseeId == currentUserId)) &&
            f.Status == FriendshipStatus.Accepted);

        if (!isFriend) return BadRequest("Nem vagytok barátok.");

        var meals = await _context.UserMeals
            .Where(m => m.UserId == friendId && m.IsCustom == true)
            .Include(m => m.Meals)
            .OrderByDescending(m => m.EatenAt)
            .Select(m => new
            {
                m.Id,
                m.CustomName,
                m.TotalCalories,
                m.TotalProtein,
                m.TotalCarbs,
                m.TotalFat,
                m.EatenAt,
                m.IsCustom,
                Meals = m.Meals.Select(mi => new
                {
                    mi.FoodId,
                    mi.Name,
                    mi.Calories,
                    mi.Proteins,
                    mi.Carbs,
                    mi.Fat,
                    mi.Quantity,
                    mi.Unit,
                    mi.BaseWeight
                }).ToList()
            })
            .ToListAsync();

        return Ok(meals);
    }

    private string GetStringValue(JsonElement element, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (element.TryGetProperty(key, out var prop) && prop.ValueKind != JsonValueKind.Null)
            {
                return prop.ToString();
            }
        }
        return string.Empty;
    }

    private double GetDoubleValue(JsonElement element, params string[] keys)
    {
        string strVal = GetStringValue(element, keys);
        if (string.IsNullOrWhiteSpace(strVal)) return 0;

        var match = Regex.Match(strVal, @"[-+]?\d+[.,]?\d*");
        if (match.Success && double.TryParse(match.Value.Replace(',', '.'), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double result))
        {
            return result;
        }
        return 0;
    }

    private string StripHtmlTags(string input)
    {
        if (string.IsNullOrEmpty(input)) return input;
        return Regex.Replace(input, "<.*?>", string.Empty).Trim();
    }
}

public class AddFoodToTemplateDto
{
    public int TemplateId { get; set; }
    public int UserId { get; set; }
    public string? FoodId { get; set; }
    public string? Name { get; set; }
    public int Quantity { get; set; }
    public int Calories { get; set; }
    public double Protein { get; set; }
    public double Carbs { get; set; }
    public double Fat { get; set; }
    public string? Unit { get; set; }
    public double? BaseWeight { get; set; }
}

public class UserMealDto
{
    public int Id { get; set; }
    public string? MealName { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string? FoodId { get; set; }
    public MealsDto? Meal { get; set; }
    public DateTime EatenAt { get; set; }
}

public class MealsDto
{
    public string? FoodId { get; set; }
    public string? Name { get; set; }
    public string? Piece { get; set; }
    public int Calories { get; set; }
    public double Protein { get; set; }
    public double Carbs { get; set; }
    public double Fat { get; set; }
    public int Quantity { get; set; }
    public string? Unit { get; set; }
    public double? BaseWeight { get; set; }
}

public class AddUserMealGroupRequest
{
    public string? MealName { get; set; }
    public string? CustomName { get; set; }
    public int UserId { get; set; }
    public DateTime? EatenAt { get; set; }
    public List<MealsDto> Meals { get; set; } = new();
    public double TotalCalories { get; set; }
    public double TotalProtein { get; set; }
    public double TotalCarbs { get; set; }
    public double TotalFat { get; set; }
    public bool IsCustom { get; set; }
}