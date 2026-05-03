using Microsoft.AspNetCore.Mvc;
using ZestAPI.Data;
using Microsoft.AspNetCore.Authorization;
using ZestAPI.Extensions;
using ZestAPI.DTOs;
using ZestAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "User")]
public class UsersController(ZestDbContext dbContext) : ControllerBase
{
    private readonly ZestDbContext _dbContext = dbContext;

    [HttpGet("me")]
    [ProducesResponseType(typeof(UserReadDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Me()
    {
        var user = (await User.ToZestUser(_dbContext))!;
        return Ok(user.ToReadDto());
    }

    [HttpPatch("me")]
    [ProducesResponseType(typeof(UserReadDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> PatchMe([FromBody] UserPatchDto patchDto)
    {
        var user = (await User.ToZestUser(_dbContext))!;

        if (!string.IsNullOrWhiteSpace(patchDto.UserName) && user.UserName != patchDto.UserName)
        {
            bool exists = await _dbContext.Users.AnyAsync(u => u.UserName == patchDto.UserName);
            if (exists) return Conflict(new ErrorResponse("Ez a felhasználónév már foglalt!"));

            user.UserName = patchDto.UserName;
        }

        if (!string.IsNullOrWhiteSpace(patchDto.Gender))
        {
            if (Enum.TryParse<Gender>(patchDto.Gender, out var gender)) user.Gender = gender;
            else return BadRequest(new ErrorResponse("Érvénytelen nem!"));
        }

        if (!string.IsNullOrWhiteSpace(patchDto.Goal))
        {
            if (Enum.TryParse<Goal>(patchDto.Goal, out var goal)) user.Goal = goal;
            else return BadRequest(new ErrorResponse("Érvénytelen cél!"));
        }

        if (!string.IsNullOrWhiteSpace(patchDto.Activity))
        {
            if (Enum.TryParse<Activity>(patchDto.Activity, out var activity)) user.Activity = activity;
            else return BadRequest(new ErrorResponse("Érvénytelen aktivitás!"));
        }

        if (patchDto.Height.HasValue) user.Height = patchDto.Height.Value;
        if (patchDto.Weight.HasValue) user.Weight = patchDto.Weight.Value;
        if (patchDto.Birth.HasValue) user.Birth = patchDto.Birth.Value;

        if (patchDto.CalorieGoal.HasValue) user.CalorieGoal = patchDto.CalorieGoal.Value;
        if (patchDto.ProteinGoal.HasValue) user.ProteinGoal = patchDto.ProteinGoal.Value;
        if (patchDto.CarbsGoal.HasValue) user.CarbsGoal = patchDto.CarbsGoal.Value;
        if (patchDto.FatGoal.HasValue) user.FatGoal = patchDto.FatGoal.Value;

        if (patchDto.ProfilePicture != null) user.ProfilePicture = patchDto.ProfilePicture;

        await _dbContext.SaveChangesAsync();

        return Ok(user.ToReadDto());
    }
}