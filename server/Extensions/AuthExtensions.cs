using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using ZestAPI.Data;
using ZestAPI.Models;

namespace ZestAPI.Extensions;

public static class AuthExtensions
{
    public static async Task<User?> ToZestUser(this ClaimsPrincipal requestAspUser, ZestDbContext db)
    {
        var userIdString = requestAspUser.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdString, out var userId))
        {
            return null;
        }

        var user = await db.Users.FirstOrDefaultAsync((x) => x.Id == userId);
        return user;
    }
}