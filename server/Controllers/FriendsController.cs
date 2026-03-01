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
            .Select(u => new { u.Id, u.UserName, u.Email, u.ProfilePicture })
            .Take(10)
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost("request/{targetUserId}")]
    public async Task<IActionResult> SendRequest(int targetUserId)
    {
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");
        var currentUserName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Valaki";

        if (currentUserId == targetUserId)
            return BadRequest("Magadat nem jelölheted be.");

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

        _ = SendPushNotification(targetUserId, currentUserName);

        return Ok(new { message = "Jelölés elküldve!" });
    }

    [HttpPost("{sessionId}/invite/{targetUserId}")]
    public async Task<IActionResult> InviteToSession(string sessionId, int targetUserId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out int currentUserId)) return Unauthorized("Érvénytelen felhasználó.");

        var hostUser = await _context.Users.FindAsync(currentUserId);
        if (hostUser == null) return NotFound("Felhasználó nem található.");

        using var client = new HttpClient();
        var request = new HttpRequestMessage(HttpMethod.Post, "https://onesignal.com/api/v1/notifications");
        
        request.Headers.Add("Authorization", "Basic ONESIGNAL_REST_API_KEY");

        var content = new StringContent($@"{{
            ""app_id"": ""ONESIGNAL_APP_ID"",
            ""include_external_user_ids"": [""{targetUserId}""],
            ""contents"": {{""en"": ""{hostUser.UserName} invited you to workout together!"", ""hu"": ""{hostUser.UserName} meghívott egy közös edzésre!""}},
            ""data"": {{ ""type"": ""session_invite"", ""sessionId"": ""{sessionId}"" }}
        }}", null, "application/json");

        request.Content = content;
        await client.SendAsync(request);

        return Ok(new { Message = "Meghívó elküldve!" });
    }

    private async Task SendPushNotification(int targetUserId, string requesterName)
    {
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

                headings = new { en = "New Friend Request", hu = "Új barátkérelem" },
                contents = new { en = $"{requesterName} sent you a friend request!", hu = $"{requesterName} barátnak jelölt téged!" },

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
                UserName = f.Requester.UserName,
                ProfilePicture = f.Requester.ProfilePicture
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
            UserName = f.RequesterId == currentUserId ? f.Addressee.UserName : f.Requester.UserName,
            ProfilePicture = f.RequesterId == currentUserId ? f.Addressee.ProfilePicture : f.Requester.ProfilePicture
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