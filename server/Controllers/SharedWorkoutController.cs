using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Zest.Api.Data;
using Zest.Api.Models;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WorkoutSessionController : ControllerBase
{
    private readonly ZestDbContext _context;

    public WorkoutSessionController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearbySessions([FromQuery] double lat, [FromQuery] double lon, [FromQuery] double radiusKm = 10)
    {
        var activeSessions = await _context.SharedWorkoutSessions
            .Include(s => s.Host)
            .Include(s => s.Participants)
            .Where(s => s.IsPublic && s.Status == Status.Lobby)
            .ToListAsync();

        var nearbySessions = activeSessions
            .Select(s => new
            {
                SessionId = s.SessionId,
                HostName = s.Host?.UserName ?? "Ismeretlen",
                Latitude = s.Latitude,
                Longitude = s.Longitude,
                ParticipantCount = s.Participants.Count,
                DistanceKm = Math.Round(CalculateDistance(lat, lon, s.Latitude, s.Longitude), 1),
                CreatedAt = s.CreatedAt
            })
            .Where(s => s.DistanceKm <= radiusKm)
            .OrderBy(s => s.DistanceKm)
            .ToList();

        return Ok(nearbySessions);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateSession([FromBody] CreateSessionRequest request)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized("Érvénytelen felhasználó.");

        string sessionId = "ZJ-" + Guid.NewGuid().ToString().Substring(0, 6).ToUpper();
        while (await _context.SharedWorkoutSessions.AnyAsync(s => s.SessionId == sessionId))
        {
            sessionId = "ZJ-" + Guid.NewGuid().ToString().Substring(0, 6).ToUpper();
        }

        var newSession = new SharedWorkoutSession
        {
            SessionId = sessionId,
            Name = request.Name,
            HostId = userId,
            Status = Status.Lobby,
            IsPublic = request.IsPublic,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            CreatedAt = DateTime.UtcNow
        };

        _context.SharedWorkoutSessions.Add(newSession);

        var hostParticipant = new SessionParticipants
        {
            SessionId = sessionId,
            UserId = userId,
            Role = Role.Host,
            IsReady = true
        };

        _context.SessionParticipants.Add(hostParticipant);
        await _context.SaveChangesAsync();

        return Ok(new { SessionId = sessionId });
    }

    [HttpPost("join")]
    public async Task<IActionResult> JoinSession([FromBody] JoinSessionRequest request)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

        var session = await _context.SharedWorkoutSessions
            .Include(s => s.Participants)
            .FirstOrDefaultAsync(s => s.SessionId == request.SessionId.ToUpper());

        if (session == null) return NotFound("A szoba nem található.");
        if (session.Status != Status.Lobby) return BadRequest("Ez az edzés már elindult vagy befejeződött.");

        if (session.Participants.Any(p => p.UserId == userId))
        {
            return Ok(new { Message = "Már csatlakoztál ehhez a szobához.", SessionId = session.SessionId });
        }

        var guest = new SessionParticipants
        {
            SessionId = session.SessionId,
            UserId = userId,
            Role = Role.Guest,
            IsReady = false
        };

        _context.SessionParticipants.Add(guest);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Sikeres csatlakozás!", SessionId = session.SessionId });
    }

    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371d;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private double ToRadians(double angle)
    {
        return Math.PI * angle / 180.0;
    }
}

public class CreateSessionRequest
{
    public string Name { get; set; } = string.Empty;
    public bool IsPublic { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class JoinSessionRequest
{
    public string SessionId { get; set; } = string.Empty;
}