using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zest.Api.Data;
using Zest.Api.Models;
using System.Security.Claims;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FriendsController : ControllerBase
{
    private readonly ZestDbContext _context;

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
        var currentUserId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        if (currentUserId == targetUserId) return BadRequest("Magadat nem jelölheted be.");

        var existing = await _context.Friendships
            .FirstOrDefaultAsync(f =>
                (f.RequesterId == currentUserId && f.AddresseeId == targetUserId) ||
                (f.RequesterId == targetUserId && f.AddresseeId == currentUserId));

        if (existing != null) return BadRequest("Már van kapcsolat köztetek.");

        var friendship = new Friendship
        {
            RequesterId = currentUserId,
            AddresseeId = targetUserId,
            Status = FriendshipStatus.Pending
        };

        _context.Friendships.Add(friendship);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Jelölés elküldve!" });
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