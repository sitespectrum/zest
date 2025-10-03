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

    [HttpPost("add")]
    public async Task<IActionResult> AddToUserMeal([FromBody] UserMealDto dto)
    {
        var userMeal = new UserMeal
        {
            UserId = dto.UserId,
            FoodId = dto.UserId,
        };

        _context.UserMeals.Add(userMeal);
        await _context.SaveChangesAsync();

        return Ok(userMeal);
    }
}

public class UserMealDto
{
    public int UserId { get; set; }
    public int MealId { get; set; }
    public double Quantity { get; set; }
}
