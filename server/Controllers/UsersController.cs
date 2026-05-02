using Microsoft.AspNetCore.Mvc;
using ZestAPI.Data;
using ZestAPI.Models;
using ZestAPI.Filters;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly ZestDbContext _dbContext;

    public UsersController(ZestDbContext dbContext, IConfiguration config)
    {
        _dbContext = dbContext;
    }

    [HttpGet("me")]
    [ValidateToken]
    public IActionResult Me()
    {
        var user = (User)HttpContext.Items["User"]!;
        return Ok(new
        {
            id = user.Id,
            username = user.UserName,
            email = user.Email,
        });
    }

}