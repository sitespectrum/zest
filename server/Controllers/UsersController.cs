using Microsoft.AspNetCore.Mvc;
using Zest.Api.Data;
using Zest.Api.Models;
using ZestApi.Filters;
using ZestApi.Middlewares;

namespace ZestApi.Controllers;

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
        var user = (User) HttpContext.Items["User"]!;
        return Ok(new
        {
            id = user.Id,
            username = user.UserName,
            email = user.Email,
        });
    }

}