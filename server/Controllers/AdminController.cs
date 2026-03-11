using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zest.Api.Data;
using Zest.Api.Models;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly ZestDbContext _context;

    public AdminController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .Select(u => new
            {
                u.Id,
                u.UserName,
                u.Email,
                u.Height,
                u.Weight,
                u.Goal,
                u.Activity,
                u.Gender
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound("Felhasználó nem található.");

        var friendships = await _context.Friendships
            .Where(f => f.RequesterId == id || f.AddresseeId == id)
            .ToListAsync();
        _context.Friendships.RemoveRange(friendships);

        var userMeals = await _context.UserMeals.Where(m => m.UserId == id).ToListAsync();
        _context.UserMeals.RemoveRange(userMeals);

        var userWorkouts = await _context.UserWorkouts.Where(w => w.UserId == id).ToListAsync();
        _context.UserWorkouts.RemoveRange(userWorkouts);

        var hostedSessions = await _context.SharedWorkoutSessions.Where(s => s.HostId == id).ToListAsync();
        _context.SharedWorkoutSessions.RemoveRange(hostedSessions);

        var participations = await _context.SessionParticipants.Where(p => p.UserId == id).ToListAsync();
        _context.SessionParticipants.RemoveRange(participations);

        var tokens = await _context.RefreshTokens.Where(t => t.UserId == id).ToListAsync();
        _context.RefreshTokens.RemoveRange(tokens);

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Felhasználó sikeresen törölve." });
    }
}