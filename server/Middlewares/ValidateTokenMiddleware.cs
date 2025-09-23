using System.IdentityModel.Tokens.Jwt;
using System.Security.Principal;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Zest.Api.Data;

namespace ZestApi.Middlewares;

public class ValidateTokenMiddleware
{
    private readonly RequestDelegate _next;

    private readonly IConfiguration _config;


    public ValidateTokenMiddleware(RequestDelegate next, IConfiguration config)
    {
        _next = next;
        _config = config;
    }

    public async Task InvokeAsync(HttpContext context, [FromServices] ZestDbContext db)
    {
        var token = context.Request.Headers.Authorization.FirstOrDefault()?.Split(" ").Last().Trim();

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config.GetValue<string>("Jwt:Key") ?? ""));

        var isValid = ValidateToken(token, [key], out JwtSecurityToken? jwt);

        if (!isValid)
        {
            context.Response.StatusCode = 401;
            return;
        }

        var sub = jwt!.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value;
        var userId = int.Parse(sub);

        var user = db.Users.FirstOrDefault(u => u.Id == userId);

        if (user == null)
        {
            context.Response.StatusCode = 401;
            return;
        }

        context.Items["User"] = user;
        
        await _next(context);
    }

    public bool ValidateToken(
        string? token,
        ICollection<SecurityKey> signingKeys,
        out JwtSecurityToken? jwt,
        string issuer = "ZestAPI",
        string audience = "ZestClient"
    )
    {
        if (token == null)
        {
            jwt = null;
            return false;
        }

        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = issuer,
            ValidateAudience = true,
            ValidAudience = audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = signingKeys,
            ValidateLifetime = true
        };

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            jwt = (JwtSecurityToken)validatedToken;

            return true;
        }
        catch (SecurityTokenValidationException)
        {
            // Log the reason why the token is not valid
            jwt = null;
            return false;
        }
    }
}
