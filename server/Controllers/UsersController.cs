using Microsoft.AspNetCore.Mvc;
using ZestAPI.Data;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using ZestAPI.Extensions;
using ZestAPI.DTOs;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController(ZestDbContext dbContext) : ControllerBase
{
    private readonly ZestDbContext _dbContext = dbContext;

    [HttpGet("me")]
    [ProducesResponseType(typeof(UserReadDto), StatusCodes.Status200OK)]
    public IActionResult Me()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userId = Convert.ToInt32(userIdString);

        var user = _dbContext.Users.Find(userId);

        if (user is null) return NotFound();

        return Ok(user.ToReadDto());
    }

}