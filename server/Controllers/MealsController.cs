using Microsoft.AspNetCore.Mvc;
using Zest.Api.Models;
using Zest.Api.Data;
using BCrypt.Net;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Zest.Api.DTOs;
using Zest.Api.Helpers;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json.Serialization;
using server.Migrations;
using System.Runtime.CompilerServices;
using System.Text.Json;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MealsController : ControllerBase
{
    private readonly ZestDbContext _context;

    private static string? _huSessionCookie;
    private static string? _enSessionCookie;

    public MealsController(ZestDbContext context)
    {
        _context = context;
    }

    private async Task<string> GetFreshSessionCookie(string baseUrl)
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

    private async Task ForceLanguage(string baseUrl, string lang, string cookie)
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

    private async Task<string> GetValidCookieForLang(string lang)
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
        if (string.IsNullOrWhiteSpace(q)) return Ok(new List<object>());

        try
        {
            var cookie = await GetValidCookieForLang("hu");

            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
            client.DefaultRequestHeaders.Add("Accept-Language", "hu-HU,hu;q=0.9");

            var uri = new UriBuilder("https://kaloriabazis.hu/getfood.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["q"] = q;
            query["p"] = "1";
            query["s"] = "8";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", $"{cookie}; kb_lang=hu");
            request.Headers.Add("X-Requested-With", "XMLHttpRequest");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode) return StatusCode((int)response.StatusCode, "Hiba a külső API-nál.");

            try { return Ok(JsonSerializer.Deserialize<object>(content)); }
            catch { return Ok(new List<object>()); }
        }
        catch (Exception ex) { return StatusCode(500, $"Szerver hiba: {ex.Message}"); }
    }

    [HttpGet("ensearch")]
    public async Task<IActionResult> ENSearch([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q)) return Ok(new List<object>());

        try
        {
            var cookie = await GetValidCookieForLang("en");

            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
            client.DefaultRequestHeaders.Add("Accept-Language", "en-US,en;q=0.9");

            var uri = new UriBuilder("https://caloriebase.com/getfood.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["q"] = q;
            query["p"] = "1";
            query["s"] = "8";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", $"{cookie}; kb_lang=en");
            request.Headers.Add("X-Requested-With", "XMLHttpRequest");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode) return StatusCode((int)response.StatusCode, "Hiba a külső API-nál.");

            try { return Ok(JsonSerializer.Deserialize<object>(content)); }
            catch { return Ok(new List<object>()); }
        }
        catch (Exception ex) { return StatusCode(500, $"Szerver hiba: {ex.Message}"); }
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

            if (root.TryGetProperty("getme", out var getmeElement))
                return Ok(JsonSerializer.Deserialize<List<object>>(getmeElement.GetRawText()));

            if (root.ValueKind == JsonValueKind.Array)
                return Ok(JsonSerializer.Deserialize<List<object>>(root.GetRawText()));

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
            MealName = Enum.Parse<MealName>(request.MealName),
            UserId = userId,
            EatenAt = request.EatenAt,
            TotalCalories = request.Meals.Sum(m => m.Calories * m.Quantity),
            TotalProtein = request.Meals.Sum(m => m.Protein * m.Quantity),
            TotalCarbs = request.Meals.Sum(m => m.Carbs * m.Quantity),
            TotalFat = request.Meals.Sum(m => m.Fat * m.Quantity),
            IsCustom = request.IsCustom,
            Meals = request.Meals.Select(m => new Meals
            {
                FoodId = m.FoodId,
                Name = m.Name,
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
            EatenAt = request.EatenAt,
            TotalCalories = request.Meals.Sum(m => m.Calories * m.Quantity),
            TotalProtein = request.Meals.Sum(m => m.Protein * m.Quantity),
            TotalCarbs = request.Meals.Sum(m => m.Carbs * m.Quantity),
            TotalFat = request.Meals.Sum(m => m.Fat * m.Quantity),
            IsCustom = request.IsCustom,
            Meals = request.Meals.Select(m => new Meals
            {
                FoodId = m.FoodId,
                Name = m.Name,
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
            FoodId = dto.FoodId,
            Name = dto.Name,
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
    public DateTime EatenAt { get; set; }
    public List<MealsDto> Meals { get; set; } = new();
    public double TotalCalories { get; set; }
    public double TotalProtein { get; set; }
    public double TotalCarbs { get; set; }
    public double TotalFat { get; set; }
    public bool IsCustom { get; set; }
}