using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Security.Claims;
using System.Text.Json;
using Zest.Api.Data;
using Zest.Api.Models;
using ZestApi.Services;

namespace ZestApi.Controllers;


[ApiController]
[Route("api/[controller]")]
public class WorkoutSessionController : ControllerBase
{
    private readonly ZestDbContext _context;
    private readonly WebSocketHandler _wsHandler;
    private readonly IMemoryCache _cache;

    private static readonly HttpClient _httpClient = new HttpClient();

    public WorkoutSessionController(ZestDbContext context, WebSocketHandler wsHandler, IMemoryCache cache)
    {
        _context = context;
        _wsHandler = wsHandler;
        _cache = cache;
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
                Name = s.Name,
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

    [HttpPost("leave")]
    public async Task<IActionResult> LeaveSession([FromBody] LeaveSessionDto request)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userIdString == null) return Unauthorized();
        var userId = int.Parse(userIdString);

        var session = await _context.SharedWorkoutSessions
            .Include(s => s.Participants)
            .FirstOrDefaultAsync(s => s.SessionId == request.SessionId.ToUpper());

        if (session == null) return NotFound("A szoba nem található.");

        var participant = session.Participants.FirstOrDefault(p => p.UserId == userId);

        if (participant != null)
        {
            _context.SessionParticipants.Remove(participant);

            if (session.HostId == userId)
            {
                var nextParticipant = session.Participants.Where(p => p.UserId != userId).OrderBy(p => p.Id).FirstOrDefault();
                if (nextParticipant != null)
                {
                    session.HostId = nextParticipant.UserId;
                    nextParticipant.Role = Role.Host;
                }
                else
                {
                    _context.SharedWorkoutSessions.Remove(session);
                }
            }

            await _context.SaveChangesAsync();
        }

        return Ok(new { Message = "Sikeresen kiléptél a szobából." });
    }

    [HttpGet("{sessionId}/participants")]
    public async Task<IActionResult> GetParticipants(string sessionId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            int.TryParse(userIdClaim, out int currentUserId);

            var cleanId = sessionId.Trim().ToUpper();
            var participants = await _context.SessionParticipants
                .Include(p => p.User)
                .Where(p => p.SessionId == sessionId.ToUpper())
                .ToListAsync();

            if (!participants.Any())
            {
                return Ok(new List<object>());
            }

            var result = participants.Select(p => new
            {
                userId = p.UserId,
                isMe = (p.UserId == currentUserId),
                userName = p.User != null ? p.User.UserName : "Ismeretlen",
                role = p.Role.ToString(),
                isReady = p.IsReady,
                profilePicture = p.User?.ProfilePicture
            });

            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, ex.InnerException != null ? ex.InnerException.Message : ex.Message);
        }
    }

    [HttpDelete("{sessionId}")]
    public async Task<IActionResult> DeleteSession(string sessionId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized("Érvénytelen felhasználó.");

        var session = await _context.SharedWorkoutSessions
            .Include(s => s.Participants)
            .FirstOrDefaultAsync(s => s.SessionId == sessionId.ToUpper());

        if (session == null) return NotFound("A szoba nem található.");
        if (session.HostId != userId) return StatusCode(403, "Csak a létrehozó törölheti az edzést.");

        _context.SessionParticipants.RemoveRange(session.Participants);
        _context.SharedWorkoutSessions.Remove(session);

        await _context.SaveChangesAsync();

        var endMessage = System.Text.Json.JsonSerializer.Serialize(new
        {
            type = "session-ended"
        });

        await _wsHandler.BroadcastToSession(sessionId.ToUpper(), endMessage);

        return Ok(new { Message = "Edzés sikeresen leállítva és törölve." });
    }

    [HttpDelete("{sessionId}/kick/{targetUserId}")]
    public async Task<IActionResult> KickUser(string sessionId, int targetUserId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int currentUserId)) return Unauthorized("Érvénytelen felhasználó.");

        var cleanId = sessionId.Trim().ToUpper();

        var session = await _context.SharedWorkoutSessions
            .Include(s => s.Participants)
            .FirstOrDefaultAsync(s => s.SessionId == cleanId);

        if (session == null) return NotFound("A szoba nem található.");

        if (session.HostId != currentUserId) return StatusCode(403, "Csak a szoba létrehozója rúghat ki tagokat.");

        var targetParticipant = session.Participants.FirstOrDefault(p => p.UserId == targetUserId);
        if (targetParticipant == null) return NotFound("A felhasználó nincs a szobában.");
        if (targetParticipant.UserId == currentUserId) return BadRequest("Magadat nem rúghatod ki.");

        var kickmessage = System.Text.Json.JsonSerializer.Serialize(new
        {
            type = "user-kicked",
            kickedUserId = targetUserId
        });

        await _wsHandler.BroadcastToSession(cleanId, kickmessage);

        _context.SessionParticipants.Remove(targetParticipant);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Felhasználó sikeresen eltávolítva." });
    }

    [HttpPost("{sessionId}/invite/{targetUserId}")]
    public async Task<IActionResult> SendPushNotification(string sessionId, int targetUserId)
    {
        Console.WriteLine($"=> MEGHÍVÓ VÉGPONT ELINDULT! Session: {sessionId}, Target: {targetUserId}");

        string cacheKey = $"invite_cooldown_{sessionId}_{targetUserId}";

        if (_cache.TryGetValue(cacheKey, out _))
        {
            Console.WriteLine($"[Spam védelem] A(z) {targetUserId} felhasználó már kapott meghívót az elmúlt 30 másodpercben.");
            return StatusCode(429, new { Message = "Kérlek, várj 30 másodpercet a következő meghívásig!" });
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int currentUserId)) return Unauthorized("Érvénytelen felhasználó.");

        var hostUser = await _context.Users.FindAsync(currentUserId);
        if (hostUser == null) return NotFound("Felhasználó nem található.");
        try
        {
            string appId = _context.Database.GetDbConnection().ConnectionString.Contains("onesignal") ? "" : "ONESIGNAL_APP_ID";
            string actualAppId = Environment.GetEnvironmentVariable("ONESIGNAL_APP_ID") ?? "";
            string restApiKey = Environment.GetEnvironmentVariable("ONESIGNAL_REST_API_KEY") ?? "";


            var notificationData = new
            {
                app_id = actualAppId,
                include_aliases = new
                {
                    external_id = new[] { targetUserId.ToString() }
                },

                target_channel = "push",

                headings = new { en = "Invite", hu = "Meghívó" },
                contents = new { en = $"{hostUser.UserName} invited you to workout together!", hu = $"{hostUser.UserName} meghívott egy közös edzésre!" },
                data = new { type = "session_invite", sessionId = sessionId },

                android_accent_color = "FF55AD4E",
                small_icon = "ic_stat_onesignal_default"
            };

            var request = new HttpRequestMessage(HttpMethod.Post, "https://onesignal.com/api/v1/notifications");
            request.Headers.Add("Authorization", $"Basic {restApiKey}");
            request.Headers.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));

            var jsonContent = JsonSerializer.Serialize(notificationData);
            request.Content = new StringContent(jsonContent, System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            Console.WriteLine($"OneSignal Válasz Kód: {response.StatusCode}");
            Console.WriteLine($"OneSignal Válasz Body: {responseBody}");

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"Kritikus OneSignal hiba: {responseBody}");
            }

            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromSeconds(30));

            _cache.Set(cacheKey, true, cacheEntryOptions);

            return Ok(new { Message = "Meghívó elküldve!" });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Hiba az értesítés küldésekor: {ex.Message}");
            return StatusCode(500, $"Belső szerver hiba: {ex.Message}");
        }
    }

    [HttpGet("ws/{sessionId}/{userId}")]
    public async Task ConnectWebSocket(string sessionId, int userId)
    {
        if (HttpContext.WebSockets.IsWebSocketRequest)
        {
            using var webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();

            await _wsHandler.HandleConnection(sessionId.ToUpper(), userId, webSocket);
        }
        else
        {
            HttpContext.Response.StatusCode = 400;
        }
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

public class LeaveSessionDto
{
    public string SessionId { get; set; } = string.Empty;
}