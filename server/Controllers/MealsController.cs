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
    public async Task<IActionResult> Search(string q)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new List<object>());

        using var client = new HttpClient();
        var response = await client.GetAsync($"https://kaloriabazis.hu/getfood.php?q={q}");
        var content = await response.Content.ReadAsStringAsync();

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

    [HttpPost("addGroup")]
    public async Task<IActionResult> AddUserMealGroup([FromBody] AddUserMealGroupRequest request)
    {
        if (request.Meals == null || !request.Meals.Any())
            return BadRequest("Legalább egy ételt meg kell adni.");

        var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
        if (!userExists)
            return BadRequest("Hibás UserId.");

        var userMeal = new UserMeal
        {
            MealName = Enum.Parse<MealName>(request.MealName),
            UserId = request.UserId,
            EatenAt = request.EatenAt,
            TotalCalories = request.TotalCalories,
            TotalProtein = request.TotalProtein,
            TotalCarbs = request.TotalCarbs,
            TotalFat = request.TotalFat
        };


        _context.UserMeals.Add(userMeal);
        await _context.SaveChangesAsync();

        foreach (var mealDto in request.Meals)
        {
            var exists = await _context.Meals.AnyAsync(m => m.FoodId == mealDto.FoodId);
            if (!exists)
            {
                var meal = new Meals
                {
                    FoodId = mealDto.FoodId,
                    Name = mealDto.Name,
                    Piece = mealDto.Piece,
                    Calories = mealDto.Calories,
                    Proteins = mealDto.Protein,
                    Carbs = mealDto.Carbs,
                    Fat = mealDto.Fat,
                };
                _context.Meals.Add(meal);
            }
        }

        await _context.SaveChangesAsync();

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
            .Select(m => new 
            {
                m.Id,
                MealName = m.MealName.ToString(),
                m.TotalCalories,
                m.TotalProtein,
                m.TotalCarbs,
                m.TotalFat,
                m.EatenAt
            })
            .ToListAsync();

        Console.WriteLine($"Talált {meals.Count} étkezést a UserId={userId}-hez");

        return Ok(meals);
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