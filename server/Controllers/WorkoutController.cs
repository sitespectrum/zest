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
using System.Text.Json;

namespace ZestApi.Controllers;

[ApiController]
[Route("api/[controller]")]

public class WorkoutController : ControllerBase
{
    private readonly ZestDbContext _context;
    private readonly HttpClient _httpClient;

    public WorkoutController(ZestDbContext context)
    {
        _context = context;
        _httpClient = new HttpClient();
    }

    [HttpPost("sync")]
    public async Task<IActionResult> SyncFromGithub()
    {
        string url = "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/dist/exercises.json";

        try
        {
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
            {
                return StatusCode((int)response.StatusCode, $"A GitHub nem elérhető: {response.ReasonPhrase}");
            }
            var JsonString = await _httpClient.GetStringAsync(url);
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var exercises = JsonSerializer.Deserialize<List<Exercise>>(JsonString, options);

            if (exercises == null || exercises.Count == 0)
            {
                return BadRequest("Nem sikerült kiolvasni az adatokat.");
            }

            int addedCount = 0;
            int updatedCount = 0;

            foreach (var item in exercises)
            {
                var existing = await _context.Exercises.FindAsync(item.Id);
                if (existing == null)
                {
                    try
                    {
                        _context.Exercises.Add(item);
                        addedCount++;
                    }
                    catch
                    {
                        System.Console.WriteLine(item);
                    }

                }
                else
                {
                    existing.Name = item.Name;
                    existing.NameHu = item.NameHu;
                    existing.Instructions = item.Instructions;
                    existing.InstructionsHu = item.InstructionsHu;
                    existing.Images = item.Images;
                    existing.PrimaryMuscles = item.PrimaryMuscles;
                    existing.PrimaryMusclesHu = item.PrimaryMusclesHu;
                    existing.SecondaryMuscles = item.SecondaryMuscles;
                    existing.SecondaryMusclesHu = item.SecondaryMusclesHu;
                    existing.Category = item.Category;
                    existing.CategoryHu = item.CategoryHu;
                    existing.Equipment = item.Equipment;
                    existing.EquipmentHu = item.EquipmentHu;
                    existing.Mechanic = item.Mechanic;
                    existing.MechanicHu = item.MechanicHu;
                    existing.Level = item.Level;
                    existing.LevelHu = item.LevelHu;
                    existing.Force = item.ForceHu;
                    updatedCount++;
                }
            }
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Szinkronizálás sikeres!",
                added = addedCount,
                updated = updatedCount,
                total = exercises.Count
            });
        }

        catch (Exception ex)
        {
            return StatusCode(500, $"Hiba: {ex.Message}");
        }
    }

    [HttpGet("search")]
    public async Task<IActionResult> SearchExercises([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new List<Exercise>());

        var qLower = q.ToLower().Trim();

        var allExercises = await _context.Exercises.ToListAsync();

        var results = await _context.Exercises
            .Where(e => e.Name.ToLower().Contains(qLower) ||
                        e.NameHu.ToLower().Contains(qLower))
                        //e.PrimaryMusclesHu.Any(m => m.ToLower().Contains(qLower)))
            .Take(20)
            .ToListAsync();

        return Ok(results);
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

    [HttpGet("muscle-groups")]
    public async Task<IActionResult> GetMuscleGroups()
    {
        var exercises = await _context.Exercises.ToListAsync();

        var muscles = exercises
            .Where(e => e.PrimaryMuscles != null)
            .SelectMany(e => e.PrimaryMuscles)
            .Select(m => m.Trim())
            .Distinct()
            .OrderBy(m => m)
            .ToList();

        return Ok(muscles);
    }

    [HttpGet("filter-by-muscle")]
    public async Task<IActionResult> FilterByMuscle([FromQuery] string muscle)
    {
        if(string.IsNullOrWhiteSpace(muscle))
            return BadRequest("Adj meg egy izomcsoportot!");
        
        var muscleLower = muscle.ToLower().Trim();

        var exercises = await _context.Exercises.ToListAsync();

        var filtered = exercises
            .Where(e => e.PrimaryMuscles != null && e.PrimaryMuscles.Any(m => m.ToLower().Trim() == muscleLower)).ToList();

        return Ok(filtered);
    }
}