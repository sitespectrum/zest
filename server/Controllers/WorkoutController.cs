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
    public async Task<IActionResult> SearchExercises([FromQuery] string q, [FromQuery] string? muscle)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new List<object>());

        var qLower = q.ToLower().Trim();

        var query = _context.Exercises
            .Where(e => e.Name.ToLower().Contains(qLower) ||
                        e.NameHu.ToLower().Contains(qLower));

        var matches = await query.ToListAsync();

        if (!string.IsNullOrWhiteSpace(muscle))
        {
            var muscleLower = muscle.ToLower().Trim();
            matches = matches.Where(e =>
                (e.PrimaryMuscles != null && e.PrimaryMuscles.Any(m => m.ToLower().Trim() == muscleLower)) ||
                (e.PrimaryMusclesHu != null && e.PrimaryMusclesHu.Any(m => m.ToLower().Trim() == muscleLower))
            ).ToList();
        }

        var results = matches.Take(20).Select(e => new
        {
            id = e.Id,
            name = e.Name,
            nameHu = e.NameHu,
            primaryMuscles = e.PrimaryMuscles,
            primaryMusclesHu = e.PrimaryMusclesHu,
            secondaryMuscles = e.SecondaryMuscles,
            secondaryMusclesHu = e.SecondaryMusclesHu,
            force = e.Force,
            forceHu = e.ForceHu,
            level = e.Level,
            levelHu = e.LevelHu,
            mechanic = e.Mechanic,
            mechanicHu = e.MechanicHu,
            equipment = e.Equipment,
            equipmentHu = e.EquipmentHu,
            category = e.Category,
            categoryHu = e.CategoryHu,
            instructions = e.Instructions,
            instructionsHu = e.InstructionsHu,
            images = e.Images
        }).ToList();

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
            .OrderByDescending(w => w.Date)
            .Select(w => new
            {
                id = w.Id,
                workoutName = w.WorkoutName,
                customName = w.CustomName,
                totalBurntCalories = w.TotalBurntCalories,
                totalLiftedWeight = w.TotalLiftedWeight,
                durationMinutes = w.DurationMinutes,
                date = w.Date,
                isCustom = w.IsCustom,

                exercises = w.Exercises.Select(we => new
                {
                    id = we.Id,
                    exerciseId = we.ExerciseId,

                    exercise = we.Exercise == null ? null : new
                    {
                        id = we.Exercise.Id,
                        name = we.Exercise.Name,
                        nameHu = we.Exercise.NameHu,
                        primaryMuscles = we.Exercise.PrimaryMuscles,
                        primaryMusclesHu = we.Exercise.PrimaryMusclesHu,
                        category = we.Exercise.Category,
                        equipment = we.Exercise.Equipment,
                        force = we.Exercise.Force,
                        level = we.Exercise.Level,
                        mechanic = we.Exercise.Mechanic,
                        images = we.Exercise.Images,
                        instructions = we.Exercise.Instructions,
                        instructionsHu = we.Exercise.InstructionsHu
                    },

                    sets = we.Sets.OrderBy(s => s.Order).Select(s => new
                    {
                        id = s.Id,
                        order = s.Order,
                        weight = s.Weight,
                        reps = s.Reps,
                        isCompleted = s.IsCompleted
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

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
            .OrderByDescending(w => w.Date)
            .Select(w => new
            {
                w.Id,
                w.CustomName,
                w.TotalBurntCalories,
                w.TotalLiftedWeight,
                w.DurationMinutes,
                w.Date,
                w.IsCustom,

                Exercises = w.Exercises.Select(we => new
                {
                    we.Id,
                    we.ExerciseId,

                    Exercise = we.Exercise == null ? null : new
                    {
                        we.Exercise.Id,
                        we.Exercise.Name,
                        we.Exercise.NameHu,
                        we.Exercise.PrimaryMuscles,
                        we.Exercise.PrimaryMusclesHu,
                        we.Exercise.Category,
                        we.Exercise.Equipment,
                        we.Exercise.Force,
                        we.Exercise.Level,
                        we.Exercise.Mechanic,
                        we.Exercise.Images,
                        we.Exercise.Instructions,
                        we.Exercise.InstructionsHu
                    },

                    Sets = we.Sets.OrderBy(s => s.Order).Select(s => new
                    {
                        s.Id,
                        s.Order,
                        s.Weight,
                        s.Reps,
                        s.IsCompleted
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

        return Ok(workouts);
    }

    [HttpGet("muscle-groups")]
    public async Task<IActionResult> GetMuscleGroups([FromQuery] string lang = "hu")
    {
        var exercises = await _context.Exercises.ToListAsync();

        List<string> muscles = new List<string>();

        if (lang == "en")
        {
            muscles = exercises
                .Where(e => e.PrimaryMuscles != null)
                .SelectMany(e => e.PrimaryMuscles)
                .Where(m => !string.IsNullOrWhiteSpace(m))
                .Select(m => m.Trim())
                .Distinct()
                .OrderBy(m => m)
                .ToList();
        }
        else
        {
            muscles = exercises
                .Where(e => e.PrimaryMusclesHu != null)
                .SelectMany(e => e.PrimaryMusclesHu)
                .Where(m => !string.IsNullOrWhiteSpace(m))
                .Select(m => m.Trim())
                .Distinct()
                .OrderBy(m => m)
                .ToList();
        }

        return Ok(muscles);
    }

    [HttpGet("filter-by-muscle")]
    public async Task<IActionResult> FilterByMuscle([FromQuery] string muscle)
    {
        if (string.IsNullOrWhiteSpace(muscle))
            return BadRequest("Adj meg egy izomcsoportot!");

        var muscleLower = muscle.ToLower().Trim();
        var exercises = await _context.Exercises.ToListAsync();

        var filteredMatches = exercises
            .Where(e =>
                (e.PrimaryMusclesHu != null && e.PrimaryMusclesHu.Any(m => m.ToLower().Trim() == muscleLower)) ||
                (e.PrimaryMuscles != null && e.PrimaryMuscles.Any(m => m.ToLower().Trim() == muscleLower))
            ).ToList();

        var results = filteredMatches.Select(e => new
        {
            id = e.Id,
            name = e.Name,
            nameHu = e.NameHu,
            primaryMuscles = e.PrimaryMuscles,
            primaryMusclesHu = e.PrimaryMusclesHu,
            secondaryMuscles = e.SecondaryMuscles,
            secondaryMusclesHu = e.SecondaryMusclesHu,
            force = e.Force,
            forceHu = e.ForceHu,
            level = e.Level,
            levelHu = e.LevelHu,
            mechanic = e.Mechanic,
            mechanicHu = e.MechanicHu,
            equipment = e.Equipment,
            equipmentHu = e.EquipmentHu,
            category = e.Category,
            categoryHu = e.CategoryHu,
            instructions = e.Instructions,
            instructionsHu = e.InstructionsHu,
            images = e.Images
        }).ToList();

        return Ok(results);
    }

    [HttpPost("AddWorkout")]
    [Authorize]
    public async Task<IActionResult> AddUserWorkout([FromBody] AddUserWorkoutRequest request)
    {
        var userId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return BadRequest("Felhasználó nem található.");

        var userWorkout = new UserWorkouts
        {
            UserId = userId,
            WorkoutName = request.WorkoutName,
            Date = request.Date,
            DurationMinutes = request.DurationMinutes,
            TotalBurntCalories = request.CaloriesBurnt,
            TotalLiftedWeight = request.TotalVolume,
            IsCustom = request.IsCustom,

            Exercises = request.Exercises.Select(e => new WorkoutExercise
            {
                ExerciseId = e.ExerciseId,
                Sets = e.Sets.Select(s => new WorkoutSet
                {
                    Weight = s.Weight,
                    Reps = s.Reps,
                    IsCompleted = s.IsCompleted
                }).ToList()
            }).ToList()
        };

        _context.UserWorkouts.Add(userWorkout);
        await _context.SaveChangesAsync();

        Console.WriteLine($"[AddUserWorkout] Saved WorkoutId: {userWorkout.Id} for UserId: {userId}");

        return Ok(new { Message = "Edzés mentése sikeres", UserWorkoutId = userWorkout.Id });
    }

    [HttpPost("AddWorkoutS")]
    [Authorize]
    public async Task<IActionResult> AddUserWorkoutS([FromBody] AddUserWorkoutRequest request)
    {

        var userId = int.Parse(User.FindFirst("id")?.Value ?? "0");

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return BadRequest("Felhasználó nem található.");

        var userWorkout = new UserWorkouts
        {
            UserId = userId,
            CustomName = request.CustomName,
            Date = request.Date,
            DurationMinutes = request.DurationMinutes,
            TotalBurntCalories = request.CaloriesBurnt,
            TotalLiftedWeight = request.TotalVolume,
            IsCustom = request.IsCustom,

            Exercises = request.Exercises.Select(e => new WorkoutExercise
            {
                ExerciseId = e.ExerciseId,
                Sets = e.Sets.Select(s => new WorkoutSet
                {
                    Weight = s.Weight,
                    Reps = s.Reps,
                    IsCompleted = s.IsCompleted
                }).ToList()
            }).ToList()
        };

        _context.UserWorkouts.Add(userWorkout);
        await _context.SaveChangesAsync();

        Console.WriteLine($"[AddUserWorkoutS] Saved WorkoutId: {userWorkout.Id} for UserId: {userId}");

        return Ok(new { Message = "Custom edzés mentése sikeres", UserWorkoutId = userWorkout.Id });
    }

    [HttpDelete("deleteUserWorkout/{id}")]
    [Authorize]
    public async Task<IActionResult> DeleteUserWorkout(int id)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null)
            return Unauthorized();

        var workout = await _context.UserWorkouts.FindAsync(id);
        if (workout == null)
            return NotFound();

        _context.UserWorkouts.Remove(workout);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("DeleteTemplate")]
    [Authorize]
    public async Task<IActionResult> DeleteTemplate([FromQuery] int id)
    {
        Console.WriteLine($"[DeleteTemplate] Kérés érkezett ID: {id}");

        var workout = await _context.UserWorkouts
            .Include(w => w.Exercises)
            .ThenInclude(e => e.Sets)
            .FirstOrDefaultAsync(w => w.Id == id);

        if (workout == null)
        {
            Console.WriteLine($"[DeleteTemplate] Hiba: Nincs ilyen ID ({id}) az adatbázisban.");
            return NotFound("Nincs ilyen edzés sablon");
        }

        var userIdClaim = User.FindFirst("id")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (userIdClaim == null)
            return Unauthorized("Nincs érvényes azonosító a tokenben.");

        var userId = int.Parse(userIdClaim);

        if (workout.UserId != userId)
            return Unauthorized("Nincs jogosultsága törölni ezt a sablont.");

        _context.UserWorkouts.Remove(workout);
        await _context.SaveChangesAsync();

        Console.WriteLine($"[DeleteTemplate] Sikeres törlés ID: {id}");

        return Ok(new { message = "Edzés sablon törlése sikeres" });
    }
}

public class AddUserWorkoutRequest
{
    public int UserId { get; set; }
    public string? WorkoutName { get; set; }
    public string? CustomName { get; set; }
    public DateTime Date { get; set; }
    public int DurationMinutes { get; set; }
    public int CaloriesBurnt { get; set; }
    public int TotalVolume { get; set; }
    public List<WorkoutExerciseDto> Exercises { get; set; }
    public bool IsCustom { get; set; }
}

public class WorkoutExerciseDto
{
    public int ExerciseId { get; set; }
    public string Name { get; set; }
    public List<WorkoutSetDto> Sets { get; set; }
}

public class WorkoutSetDto
{
    public double Weight { get; set; }
    public int Reps { get; set; }
    public bool IsCompleted { get; set; }
}