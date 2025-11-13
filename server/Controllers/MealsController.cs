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

[ApiController]
[Route("api/[controller]")]
public class MealsController : ControllerBase
{
    private readonly ZestDbContext _context;

    public MealsController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new List<object>());

        try
        {
            using var client = new HttpClient();

            var uri = new UriBuilder("https://kaloriabazis.hu/getfood.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["q"] = q;
            query["p"] = "1";
            query["s"] = "1000";
            query["expropsearch_id"] = "0";
            query["expropsearch_inc"] = "0";
            query["all_public_food"] = "0";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", "myPHP83SESSID=TociayuHeV0zm54lJNEDnBhxJy;");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, "Hiba a külső API-nál.");

            try
            {
                var parsed = System.Text.Json.JsonSerializer.Deserialize<object>(content);
                return Ok(parsed);
            }
            catch
            {
                return Ok(new List<object>());
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Szerver hiba: {ex.Message}");
        }
    }

    [HttpGet("get-units")]
    public async Task<IActionResult> GetUnits([FromQuery] string foodId)
    {
        if (string.IsNullOrWhiteSpace(foodId))
            return BadRequest(new { error = "foodId kötelező." });

        try
        {
            using var client = new HttpClient();

            var uri = new UriBuilder("https://kaloriabazis.hu/food.php");
            Console.WriteLine($"[DEBUG] Hívott URL: {uri}");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["show"] = "getmenew";
            query["id"] = foodId;
            query["food_id_special"] = "0";
            query["food_id_directly"] = "1";
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", "myPHP83SESSID=TociayuHeV0zm54lJNEDnBhxJy;");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, new { error = "Hiba a külső API-nál." });

            if (content.TrimStart().StartsWith("<"))
            {
                return StatusCode(500, new { error = "A külső API nem JSON-t adott vissza (valószínűleg lejárt a session cookie)." });
            }

            using var jsonDoc = System.Text.Json.JsonDocument.Parse(content);
            var root = jsonDoc.RootElement;

            if (root.TryGetProperty("getme", out var getmeElement))
            {
                var list = System.Text.Json.JsonSerializer.Deserialize<List<object>>(getmeElement.GetRawText());
                return Ok(list);
            }

            if (root.ValueKind == System.Text.Json.JsonValueKind.Array)
            {
                var list = System.Text.Json.JsonSerializer.Deserialize<List<object>>(root.GetRawText());
                return Ok(list);
            }

            return Ok(new { raw = root });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = $"Szerver hiba: {ex.Message}" });
        }
    }

    [HttpGet("get-by-barcode")]
    public async Task<IActionResult> GetByBarcode([FromQuery] string code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return BadRequest("code kötelező.");

        try
        {
            using var client = new HttpClient();

            var uri = new UriBuilder("https://kaloriabazis.hu/barcode_ajax.php");
            var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
            query["show"] = "get_food_info_from_bcode";
            query["bcode"] = code;
            uri.Query = query.ToString();

            var request = new HttpRequestMessage(HttpMethod.Get, uri.ToString());
            request.Headers.Add("Cookie", "myPHP83SESSID=TociayuHeV0zm54lJNEDnBhxJy;");

            var response = await client.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, "Hiba a külső API-nál.");

            var parsed = System.Text.Json.JsonSerializer.Deserialize<object>(content);
            return Ok(parsed);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Szerver hiba: {ex.Message}");
        }
    }

    [HttpPost("addGroup")]
    [Authorize]
    public async Task<IActionResult> AddUserMealGroup([FromBody] AddUserMealGroupRequest request)
    {
        // Tokenből user azonosító
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
            Meals = request.Meals.Select(m => new Meals
            {
                FoodId = m.FoodId,
                Name = m.Name,
                Piece = m.Piece,
                Calories = m.Calories,
                Proteins = m.Protein,
                Carbs = m.Carbs,
                Fat = m.Fat,
                Quantity = m.Quantity
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
    public int UserId { get; set; }
    public DateTime EatenAt { get; set; }
    public List<MealsDto> Meals { get; set; } = new();
    public double TotalCalories { get; set; }
    public double TotalProtein { get; set; }
    public double TotalCarbs { get; set; }
    public double TotalFat { get; set; }
}