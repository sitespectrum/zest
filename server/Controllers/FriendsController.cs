using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zest.Api.Data;
using Zest.Api.Models;
using System.Security.Claims;
using System.Net.Http;
using System.Text.Json;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FriendsController : ControllerBase
{
    private readonly ZestDbContext _context;
    private static readonly HttpClient _httpClient = new HttpClient();

    public FriendsController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpGet("search")]
    public async Task<IActionResult> SearchUsers([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return Ok(new List<object>());

        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var existingConnections = await _context.Friendships
            .Where(f => f.RequesterId == currentUserId || f.AddresseeId == currentUserId)
            .ToListAsync();

        var excludedUserIds = existingConnections
            .Select(f => f.RequesterId == currentUserId ? f.AddresseeId : f.RequesterId)
            .ToList();

        excludedUserIds.Add(currentUserId);

        var users = await _context.Users
            .Where(u => u.UserName.Contains(query) && !excludedUserIds.Contains(u.Id))
            .Select(u => new { u.Id, u.UserName, u.Email })
            .Take(10)
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost("request/{targetUserId}")]
    public async Task<IActionResult> SendRequest(int targetUserId)
    {
        // A bejelentkezett felhasználó ID-ja és neve a Tokenből
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");
        var currentUserName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Valaki";

        if (currentUserId == targetUserId)
            return BadRequest("Magadat nem jelölheted be.");

        // Ellenőrizzük, van-e már kapcsolat
        var existing = await _context.Friendships
            .FirstOrDefaultAsync(f =>
                (f.RequesterId == currentUserId && f.AddresseeId == targetUserId) ||
                (f.RequesterId == targetUserId && f.AddresseeId == currentUserId));

        if (existing != null)
            return BadRequest("Már van kapcsolat köztetek.");

        var friendship = new Friendship
        {
            RequesterId = currentUserId,
            AddresseeId = targetUserId,
            Status = FriendshipStatus.Pending
        };

        _context.Friendships.Add(friendship);
        await _context.SaveChangesAsync();

        // Értesítés küldése a háttérben, hogy ne lassítsa a választ
        _ = SendPushNotification(targetUserId, currentUserName);

        return Ok(new { message = "Jelölés elküldve!" });
    }

    private async Task SendPushNotification(int targetUserId, string requesterName)
    {
        try
        {
            // OneSignal azonosítók (Ezt a OneSignal Dashboardon találod)
            string appId = Environment.GetEnvironmentVariable("ONESIGNAL_APP_ID") ?? "";
            string restApiKey = Environment.GetEnvironmentVariable("ONESIGNAL_REST_API_KEY") ?? "";

            var notificationData = new
            {
                app_id = appId,
                // A célzott felhasználó ID-ja (External User ID), amit a Flutterben is beállítasz
                include_external_user_ids = new[] { targetUserId.ToString() },
                headings = new { en = "New Friend Request", hu = "Új barátkérelem" },
                contents = new { en = $"{requesterName} sent you a friend request!", hu = $"{requesterName} barátnak jelölt téged!" },
                // Opcionális: kis ikon vagy hang beállítása
                android_accent_color = "FF55AD4E"
            };

            var request = new HttpRequestMessage(HttpMethod.Post, "https://onesignal.com/api/v1/notifications");
            request.Headers.Add("Authorization", $"Basic {restApiKey}");
            request.Content = new StringContent(JsonSerializer.Serialize(notificationData), System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.SendAsync(request);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"OneSignal hiba: {error}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Hiba az értesítés küldésekor: {ex.Message}");
        }
    }

    [HttpGet("requests")]
    public async Task<IActionResult> GetPendingRequests()
    {
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var requests = await _context.Friendships
            .Where(f => f.AddresseeId == currentUserId && f.Status == FriendshipStatus.Pending)
            .Include(f => f.Requester)
            .Select(f => new
            {
                RequestId = f.Id,
                UserId = f.Requester.Id,
                UserName = f.Requester.UserName
            })
            .ToListAsync();

        return Ok(requests);
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetFriends()
    {
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var friends = await _context.Friendships
            .Where(f => (f.RequesterId == currentUserId || f.AddresseeId == currentUserId)
                        && f.Status == FriendshipStatus.Accepted)
            .Include(f => f.Requester)
            .Include(f => f.Addressee)
            .ToListAsync();

        var result = friends.Select(f => new
        {
            Id = f.RequesterId == currentUserId ? f.Addressee.Id : f.Requester.Id,
            UserName = f.RequesterId == currentUserId ? f.Addressee.UserName : f.Requester.UserName
        });

        return Ok(result);
    }

    [HttpPost("respond")]
    public async Task<IActionResult> RespondToRequest([FromBody] RespondDto dto)
    {
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var friendship = await _context.Friendships.FindAsync(dto.RequestId);

        if (friendship == null || friendship.AddresseeId != currentUserId)
            return BadRequest("Nem található ilyen kérelem.");

        if (dto.Accept)
        {
            friendship.Status = FriendshipStatus.Accepted;
        }
        else
        {
            _context.Friendships.Remove(friendship);
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = dto.Accept ? "Elfogadva!" : "Elutasítva." });
    }

    [HttpDelete("delete/{friendId}")]
    public async Task<IActionResult> RemoveFriend(int friendId)
    {
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var friendship = await _context.Friendships
            .FirstOrDefaultAsync(f =>
                (f.RequesterId == currentUserId && f.AddresseeId == friendId) ||
                (f.RequesterId == friendId && f.AddresseeId == currentUserId));

        if (friendship == null)
        {
            return NotFound("Nem található a kapcsolat.");
        }

        _context.Friendships.Remove(friendship);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Barát sikeresen törölve." });
    }
}

public class RespondDto
{
    public int RequestId { get; set; }
    public bool Accept { get; set; }
}