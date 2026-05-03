using Microsoft.AspNetCore.Mvc;
using ZestAPI.Models;
using ZestAPI.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using ZestAPI.DTOs;
using Microsoft.AspNetCore.Authorization;
using ZestAPI.Extensions;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "User")]
public class AuthController(ZestDbContext dbContext, IConfiguration config) : ControllerBase
{
    private readonly ZestDbContext _dbContext = dbContext;
    private readonly IConfiguration _config = config;

    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new ErrorResponse("Email és Jelszó megadása kötelező!"));

        if (!IsValidEmail(request.Email))
            return BadRequest(new ErrorResponse("Érvénytelen email!"));

        if (await _dbContext.Users.AnyAsync(u => u.UserName == request.UserName))
            return Conflict(new ErrorResponse("Ezzel a felhasználónévvel már van regisztrált felhasználó!"));

        if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            return Conflict(new ErrorResponse("Ezzel az emaillel már van regisztrált felhasználó!"));

        var user = new User
        {
            Email = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            UserName = request.UserName
        };

        await _dbContext.Users.AddAsync(user);
        await _dbContext.SaveChangesAsync();

        var expirationDays = _config.GetValue<int>("Jwt:RefreshTokenExpirationDays");
        var refreshToken = new RefreshToken
        {
            Token = GenerateRefreshToken(),
            UserId = user.Id,
            RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(expirationDays)
        };
        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync();

        var accessToken = GenerateJwtToken(user, refreshToken);

        return Ok(new LoginResponse(
            accessToken,
            refreshToken.Token
        ));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.UserName == dto.UserName || u.Email == dto.UserName);
        var passwordMatches = BCrypt.Net.BCrypt.Verify(dto.Password, user?.PasswordHash);

        if (user == null || !passwordMatches) return Unauthorized(new ErrorResponse("Invalid username or password!"));

        var expirationDays = _config.GetValue<int>("Jwt:RefreshTokenExpirationDays");
        var refreshToken = new RefreshToken
        {
            Token = GenerateRefreshToken(),
            UserId = user.Id,
            RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(expirationDays)
        };
        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync();

        var accessToken = GenerateJwtToken(user, refreshToken);

        return Ok(new LoginResponse(
            accessToken,
            refreshToken.Token
        ));
    }

    [HttpPost("logout")]
    [ProducesResponseType(typeof(SimpleMessageResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Logout()
    {
        var rtIdString = User.FindFirstValue("rtid");
        var rtId = int.Parse(rtIdString ?? "0");
        var existing = await _dbContext.RefreshTokens.FirstOrDefaultAsync(x => x.Id == rtId);
        if (existing is null)
            return NotFound(new ErrorResponse("Ez a token már nem létezik"));

        _dbContext.RefreshTokens.Remove(existing);
        await _dbContext.SaveChangesAsync();

        return Ok(new SimpleMessageResponse("Sikeres kijelentkezés."));
    }

    [HttpPost("refresh")]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request)
    {
        var token = _dbContext.RefreshTokens.FirstOrDefault(t => t.Token == request.RefreshToken);
        var user = (await User.ToZestUser(_dbContext))!;

        if (token == null || user == null || token?.RefreshTokenExpiryTime <= DateTime.UtcNow)
            return Unauthorized(new ErrorResponse("Invalid or expired refresh token"));

        _dbContext.Remove(token!);

        var expirationDays = _config.GetValue<int>("Jwt:RefreshTokenExpirationDays");
        var refreshToken = new RefreshToken
        {
            Token = GenerateRefreshToken(),
            UserId = user.Id,
            RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(expirationDays)
        };
        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync();

        var accessToken = GenerateJwtToken(user, refreshToken);

        return Ok(new LoginResponse(
            accessToken,
            refreshToken.Token
        ));
    }

    [HttpPut("updatePassword")]
    [ProducesResponseType(typeof(SimpleMessageResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdatePassword([FromBody] UpdatePasswordRequest request)
    {
        var user = (await User.ToZestUser(_dbContext))!;

        if (string.IsNullOrWhiteSpace(request.NewPassword))
            return BadRequest(new ErrorResponse("Az új jelszó nem lehet üres!"));

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        _dbContext.Users.Update(user);
        await _dbContext.SaveChangesAsync();

        return Ok(new SimpleMessageResponse("Jelszó sikeresen megváltoztatva!"));
    }

    private static string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }
    private string GenerateJwtToken(User user, RefreshToken refreshToken)
    {
        List<Claim> claims = [
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.UserName),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Role, "User"),
            new("rtid", refreshToken.Id.ToString()),
        ];

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? ""));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static bool IsValidEmail(string email)
    {
        var atIdx = email.IndexOf('@');
        if (atIdx == -1) return false;
        if (atIdx == email.Length - 1) return false;
        if (atIdx == 0) return false;
        if (atIdx != email.LastIndexOf('@')) return false;

        return true;
    }
}

public record LoginResponse(string Token, string RefreshToken);

public class RegisterRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public string UserName { get; set; } = "";
}

public class DetailsRequest
{
    public int? UserId { get; set; }
    public string? UserName { get; set; }
    public int? Height { get; set; }
    public int? Weight { get; set; }
    public DateTime? Birth { get; set; }
    public string? Gender { get; set; }
    public string? Goal { get; set; }
    public string? Activity { get; set; }
    public double CalorieGoal { get; set; }
    public double ProteinGoal { get; set; }
    public double CarbsGoal { get; set; }
    public double FatGoal { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public class UpdateCalorieGoalRequest
{
    public double CalorieGoal { get; set; }
}

public class UpdatePasswordRequest
{
    public string NewPassword { get; set; } = "";
}