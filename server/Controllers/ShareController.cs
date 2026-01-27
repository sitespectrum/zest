using Microsoft.AspNetCore.Mvc;
using Zest.Api.Data;
using Zest.Api.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ShareController : ControllerBase
{
    private readonly ZestDbContext _context;

    public ShareController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpPost("uploadWorkout")]
    public async Task<IActionResult> UploadShareWorkout([FromBody] object workoutData)
    {
        try
        {
            string shareId = Guid.NewGuid().ToString().Substring(0, 5).ToUpper();

            while (await _context.SharedWorkouts.AnyAsync(s => s.Id == shareId))
            {
                shareId = Guid.NewGuid().ToString().Substring(0, 5).ToUpper();
            }

            var share = new SharedWorkouts
            {
                Id = shareId,
                JsonData = JsonSerializer.Serialize(workoutData),
                CreatedAt = DateTime.UtcNow
            };

            _context.SharedWorkouts.Add(share);
            await _context.SaveChangesAsync();

            var oldShares = _context.SharedWorkouts.Where(s => s.CreatedAt < DateTime.UtcNow.AddDays(-1));
            if (oldShares.Any())
            {
                _context.SharedWorkouts.RemoveRange(oldShares);
                await _context.SaveChangesAsync();
            }

            return Ok(new { shareId = shareId });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Hiba a megosztásnál: {ex.Message}");
        }
    }

    [HttpGet("workout-{id}")]
    public async Task<IActionResult> GetShareWorkout(string id)
    {
        var share = await _context.SharedWorkouts.FindAsync(id.ToUpper());

        if (share == null)
        {
            return NotFound("A megosztás nem található vagy lejárt.");
        }

        return Content(share.JsonData, "application/json");
    }

    [HttpPost("uploadMeal")]
    public async Task<IActionResult> UploadShareMeal([FromBody] object workoutData)
    {
        try
        {
            string shareId = Guid.NewGuid().ToString().Substring(0, 5).ToUpper();

            while (await _context.SharedWorkouts.AnyAsync(s => s.Id == shareId))
            {
                shareId = Guid.NewGuid().ToString().Substring(0, 5).ToUpper();
            }

            var share = new SharedWorkouts
            {
                Id = shareId,
                JsonData = JsonSerializer.Serialize(workoutData),
                CreatedAt = DateTime.UtcNow
            };

            _context.SharedWorkouts.Add(share);
            await _context.SaveChangesAsync();

            var oldShares = _context.SharedWorkouts.Where(s => s.CreatedAt < DateTime.UtcNow.AddDays(-1));
            if (oldShares.Any())
            {
                _context.SharedWorkouts.RemoveRange(oldShares);
                await _context.SaveChangesAsync();
            }

            return Ok(new { shareId = shareId });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Hiba a megosztásnál: {ex.Message}");
        }
    }

    [HttpGet("meal-{id}")]
    public async Task<IActionResult> GetShareMeal(string id)
    {
        var share = await _context.SharedWorkouts.FindAsync(id.ToUpper());

        if (share == null)
        {
            return NotFound("A megosztás nem található vagy lejárt.");
        }

        return Content(share.JsonData, "application/json");
    }
}