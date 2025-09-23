using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Zest.Api.Data;

namespace ZestApi.Filters;

public class ValidateTokenAttribute : TypeFilterAttribute<ValidateTokenFilter>
{
}

public class ValidateTokenFilter : IAsyncActionFilter
{
    private readonly ZestDbContext _dbContext;
    private readonly IConfiguration _config;


    public ValidateTokenFilter(ZestDbContext dbContext, IConfiguration config)
    {
        _dbContext = dbContext;
        _config = config;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        Console.WriteLine("Validate token started");
        var token = context.HttpContext.Request.Headers.Authorization.FirstOrDefault()?.Split(" ").Last().Trim();

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config.GetValue<string>("Jwt:Key") ?? ""));

        var isValid = ValidateToken(token, [key], out JwtSecurityToken? jwt);

        if (!isValid)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var sub = jwt!.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value;
        var userId = int.Parse(sub);

        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        context.HttpContext.Items["User"] = user;

        await next();
    }

    public bool ValidateToken(
        string? token,
        ICollection<SecurityKey> signingKeys,
        out JwtSecurityToken? jwt,
        string issuer = "ZestApi",
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
        catch (SecurityTokenValidationException ex)
        {
            Console.WriteLine(ex.Message);
            jwt = null;
            return false;
        }
    }
}