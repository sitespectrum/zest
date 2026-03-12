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
    private readonly IConfiguration _configuration;

    public AdminController(ZestDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public class AdminLoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    [HttpPost("login")]
    public IActionResult Login([FromBody] AdminLoginRequest request)
    {
        var adminUser = Environment.GetEnvironmentVariable("ADMIN_USERNAME");
        var adminPass = Environment.GetEnvironmentVariable("ADMIN_PASSWORD");

        if (string.IsNullOrEmpty(adminUser) || string.IsNullOrEmpty(adminPass))
        {
            return StatusCode(500, new { message = "Szerver hiba: Admin adatok nincsenek beállítva a .env fájlban!" });
        }

        if (request.Username == adminUser && request.Password == adminPass)
        {
            var tokenString = $"{adminUser}-ZestAdminToken-{DateTime.UtcNow.Day}";
            var adminToken = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(tokenString));

            return Ok(new { token = adminToken, username = adminUser });
        }

        return Unauthorized(new { message = "Hibás felhasználónév vagy jelszó!" });
    }

    private bool IsAdminAuthorized()
    {
        var authHeader = Request.Headers["Authorization"].ToString();
        var adminUser = Environment.GetEnvironmentVariable("ADMIN_USERNAME") ?? _configuration["ADMIN_USERNAME"];

        var expectedTokenString = $"{adminUser}-ZestAdminToken-{DateTime.UtcNow.Day}";
        var expectedToken = "Bearer " + Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(expectedTokenString));

        return authHeader == expectedToken;
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        if (!IsAdminAuthorized()) return Unauthorized(new { message = "Nincs jogosultságod! Jelentkezz be újra." });

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
        if (!IsAdminAuthorized()) return Unauthorized(new { message = "Nincs jogosultságod! Jelentkezz be újra." });

        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound("Felhasználó nem található.");

        var friendships = await _context.Friendships.Where(f => f.RequesterId == id || f.AddresseeId == id).ToListAsync();
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