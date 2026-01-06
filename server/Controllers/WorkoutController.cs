using Microsoft.AspNetCore.Mvc;
using Zest.Api.Models;
using Zest.Api.Data;
using BCrypt.Net;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Zest.Api.DTOs;
using Zest.Api.Helpers;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json.Serialization;
using server.Migrations;
using System.Runtime.CompilerServices;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]

public class WorkoutController : ControllerBase
{
    private readonly ZestDbContext _context;

    public WorkoutController(ZestDbContext context)
    {
        _context = context;
    }

    [HttpGet("getUserWorkouts")]
    [Authorize]
    public async Task<IActionResult> GetUserWorkouts()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var workouts = await _context.UserWorkouts
            .Where(w => w.UserId == userId)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Exercise)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Sets)
            .OrderByDescending(w => w.Date)
            .Select(w => new
            {
                w.Id,
                CustomName = w.WorkoutName,
                w.TotalBurntCalories,
                w.TotalLiftedWeight,
                w.DurationMinutes,
                w.Date,
                w.IsCustom,

                Exercises = w.Exercises.Select(we => new
                {
                    we.Id,
                    we.ExerciseId,

                    Name = we.Exercise != null ? we.Exercise.Name : "Ismeretlen gyakorlat",
                    Images = we.Exercise != null ? we.Exercise.Images : new List<string>(),

                    Sets = we.Sets.OrderBy(s => s.Order).Select(s => new
                    {
                        s.Id,
                        s.Order,
                        s.Weight,
                        s.Reps,
                        s.IsWarmup
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

        Console.WriteLine($"Talált {workouts.Count} edzés sablont a UserId={userId}-hez");

        return Ok(workouts);
    }

    [HttpGet("getCustomUserWorkouts")]
    [Authorize]
    public async Task<IActionResult> GetCustomUserWorkouts()
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();

        var userId = int.Parse(userIdClaim);

        var workouts = await _context.UserWorkouts
            .Where(w => w.UserId == userId && w.IsCustom == true)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Exercise)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Sets)
            .OrderByDescending(w => w.Date)
            .Select(w => new
            {
                w.Id,
                CustomName = w.WorkoutName,
                w.TotalBurntCalories,
                w.TotalLiftedWeight,
                w.DurationMinutes,
                w.Date,
                w.IsCustom,

                Exercises = w.Exercises.Select(we => new
                {
                    we.Id,
                    we.ExerciseId,

                    Name = we.Exercise != null ? we.Exercise.Name : "Ismeretlen gyakorlat",
                    Images = we.Exercise != null ? we.Exercise.Images : new List<string>(),

                    Sets = we.Sets.OrderBy(s => s.Order).Select(s => new
                    {
                        s.Id,
                        s.Order,
                        s.Weight,
                        s.Reps,
                        s.IsWarmup
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

        Console.WriteLine($"Talált {workouts.Count} edzés sablont a UserId={userId}-hez");

        return Ok(workouts);
    }
}