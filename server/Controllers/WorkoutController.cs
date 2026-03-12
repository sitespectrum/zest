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
            var fixSql = "UPDATE sqlite_sequence SET seq = (SELECT MAX(Id) FROM Exercises) WHERE name = 'Exercises'";
            await _context.Database.ExecuteSqlRawAsync(fixSql);

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

    [HttpPost("fix-sequence")]
    public async Task<IActionResult> FixSqliteSequence()
    {
        try
        {
            var maxId = await _context.Exercises.MaxAsync(e => (int?)e.Id) ?? 0;

            Console.WriteLine($"[FixSequence] Talált legnagyobb ID: {maxId}");

            await _context.Database.ExecuteSqlRawAsync("DELETE FROM sqlite_sequence WHERE name = 'Exercises'");
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM sqlite_sequence WHERE name = 'exercises'");

            var sql = $"INSERT INTO sqlite_sequence (name, seq) VALUES ('Exercises', {maxId})";
            await _context.Database.ExecuteSqlRawAsync(sql);

            return Ok($"Siker! Adatbázis Max ID: {maxId}. A számláló beállítva {maxId}-ra. Próbálj menteni!");
        }
        catch (Exception ex)
        {
            return BadRequest($"Kritikus hiba a javítás közben: {ex.Message}");
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
                        distance = s.Distance,
                        durationSeconds = s.DurationSeconds,
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
                        s.Distance,
                        s.DurationSeconds,
                        s.IsCompleted
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

        return Ok(workouts);
    }

    [HttpGet("official-templates")]
    public async Task<IActionResult> GetOfficialTemplates()
    {
        var officialUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "official@zest.app");
        if (officialUser == null) return Ok(new List<object>());

        var templates = await _context.UserWorkouts
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Exercise)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Sets)
            .Where(w => w.UserId == officialUser.Id && w.IsCustom == true)
            .OrderByDescending(w => w.Date)
            .ToListAsync();

        return Ok(templates);
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
            Date = request.Date ?? DateTime.MinValue,
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

    [HttpPost("newExercise")]
    public async Task<IActionResult> SaveNewExercise([FromBody] AddExerciseRequest request)
    {
        var maxId = await _context.Exercises.MaxAsync(e => (int?)e.Id) ?? 0;
        var nextId = maxId + 1;

        var exercise = new Exercise
        {
            Id = nextId,
            Name = request.Name,
            NameHu = request.Lang == "hu" ? request.Name : null,
            Instructions = new List<string> { "Custom exercise created by user." },
            InstructionsHu = new List<string> { "Felhasználó által létrehozott gyakorlat." },
        };

        var equipPair = await ResolveTerm(request.Equipment, "Equipment", request.Lang);
        exercise.Equipment = equipPair.En;
        exercise.EquipmentHu = equipPair.Hu;

        var forcePair = await ResolveTerm(request.Force, "Force", request.Lang);
        exercise.Force = forcePair.En;
        exercise.ForceHu = forcePair.Hu;

        var primaryPair = await ResolveMuscleList(request.PrimaryMuscles, request.Lang);
        exercise.PrimaryMuscles = primaryPair.En;
        exercise.PrimaryMusclesHu = primaryPair.Hu;

        var secondaryPair = await ResolveMuscleList(request.SecondaryMuscles, request.Lang);
        exercise.SecondaryMuscles = secondaryPair.En;
        exercise.SecondaryMusclesHu = secondaryPair.Hu;

        _context.Exercises.Add(exercise);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Sikeres mentés!", id = nextId });
    }

    private async Task<(List<string> En, List<string> Hu)> ResolveMuscleList(List<string> values, string fallbackLang)
    {
        var enList = new List<string>();
        var huList = new List<string>();

        if (values == null || !values.Any()) return (enList, huList);

        var allMuscles = await _context.Exercises
            .AsNoTracking()
            .Select(e => new { e.PrimaryMuscles, e.PrimaryMusclesHu, e.SecondaryMuscles, e.SecondaryMusclesHu })
            .ToListAsync();

        foreach (var val in values)
        {
            var valLower = val.ToLower().Trim();
            bool found = false;

            foreach (var m in allMuscles)
            {
                bool isEnglish = (m.PrimaryMuscles != null && m.PrimaryMuscles.Any(x => x.ToLower().Trim() == valLower)) ||
                                 (m.SecondaryMuscles != null && m.SecondaryMuscles.Any(x => x.ToLower().Trim() == valLower));

                bool isHungarian = (m.PrimaryMusclesHu != null && m.PrimaryMusclesHu.Any(x => x.ToLower().Trim() == valLower)) ||
                                   (m.SecondaryMusclesHu != null && m.SecondaryMusclesHu.Any(x => x.ToLower().Trim() == valLower));

                if (isEnglish || isHungarian)
                {

                    string? foundEn = null;
                    string? foundHu = null;

                    if (m.PrimaryMuscles != null && m.PrimaryMuscles.Count > 0) foundEn = m.PrimaryMuscles[0];
                    else if (m.SecondaryMuscles != null && m.SecondaryMuscles.Count > 0) foundEn = m.SecondaryMuscles[0];

                    if (m.PrimaryMusclesHu != null && m.PrimaryMusclesHu.Count > 0) foundHu = m.PrimaryMusclesHu[0];
                    else if (m.SecondaryMusclesHu != null && m.SecondaryMusclesHu.Count > 0) foundHu = m.SecondaryMusclesHu[0];

                    if (isEnglish) foundEn = val;

                    if (!string.IsNullOrEmpty(foundEn)) enList.Add(foundEn);
                    if (!string.IsNullOrEmpty(foundHu)) huList.Add(foundHu);

                    found = true;
                    break;
                }
            }

            if (!found)
            {
                if (fallbackLang == "hu") huList.Add(val);
                else enList.Add(val);
            }
        }

        return (enList.Distinct().ToList(), huList.Distinct().ToList());
    }

    private async Task<(string? En, string? Hu)> ResolveTerm(string? value, string fieldType, string fallbackLang)
    {
        if (string.IsNullOrWhiteSpace(value)) return (null, null);

        var valLower = value.ToLower().Trim();

        var lookupData = await _context.Exercises
            .AsNoTracking()
            .Select(e => new { e.Equipment, e.EquipmentHu, e.Force, e.ForceHu })
            .ToListAsync();

        var match = lookupData.FirstOrDefault(e =>
            (e.Equipment != null && e.Equipment.ToLower().Trim() == valLower) ||
            (e.EquipmentHu != null && e.EquipmentHu.ToLower().Trim() == valLower) ||
            (e.Force != null && e.Force.ToLower().Trim() == valLower) ||
            (e.ForceHu != null && e.ForceHu.ToLower().Trim() == valLower)
        );

        if (match != null)
        {
            if (fieldType == "Equipment") return (match.Equipment, match.EquipmentHu);
            if (fieldType == "Force") return (match.Force, match.ForceHu);
        }

        if (fallbackLang == "hu") return (null, value);
        else return (value, null);
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
            Date = request.Date ?? DateTime.MinValue,
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
                    Distance = s.Distance ?? 0,
                    DurationSeconds = s.DurationSeconds ?? 0,
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

    [HttpGet("getFriendCustomWorkouts/{friendId}")]
    [Authorize]
    public async Task<IActionResult> GetFriendCustomWorkouts(int friendId)
    {
        var currentUserIdClaim = User.FindFirst("id")?.Value;
        if (currentUserIdClaim == null) return Unauthorized();
        var currentUserId = int.Parse(currentUserIdClaim);

        var isFriend = await _context.Friendships.AnyAsync(f =>
            ((f.RequesterId == currentUserId && f.AddresseeId == friendId) ||
             (f.RequesterId == friendId && f.AddresseeId == currentUserId)) &&
            f.Status == FriendshipStatus.Accepted);

        if (!isFriend) return BadRequest("Nem vagytok barátok, vagy a barátság nincs elfogadva.");

        var workouts = await _context.UserWorkouts
            .Where(w => w.UserId == friendId && w.IsCustom == true)
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
                        we.Exercise.PrimaryMusclesHu,
                        we.Exercise.Images
                    },
                    Sets = we.Sets.OrderBy(s => s.Order).Select(s => new
                    {
                        s.Id,
                        s.Order,
                        s.Weight,
                        s.Reps,
                        s.Distance,
                        s.DurationSeconds,
                        s.IsCompleted
                    }).ToList()
                }).ToList()
            })
            .ToListAsync();

        return Ok(workouts);
    }

    [HttpGet("getExerciseHistory/{exerciseId}")]
    [Authorize]
    public async Task<IActionResult> GetExerciseHistory(int exerciseId)
    {
        var userIdClaim = User.FindFirst("id")?.Value;
        if (userIdClaim == null) return Unauthorized();
        var userId = int.Parse(userIdClaim);

        var history = await _context.UserWorkouts
            .Where(w => w.UserId == userId && w.Exercises.Any(e => e.ExerciseId == exerciseId))
            .OrderByDescending(w => w.Date)
            .Take(10)
            .Select(w => new
            {
                WorkoutId = w.Id,
                Date = w.Date,
                WorkoutName = w.WorkoutName ?? w.CustomName,
                Sets = w.Exercises
                        .Where(e => e.ExerciseId == exerciseId)
                        .SelectMany(e => e.Sets)
                        .OrderBy(s => s.Order)
                        .Select(s => new
                        {
                            Weight = s.Weight,
                            Reps = s.Reps,
                            Distance = s.Distance,
                            DurationSeconds = s.DurationSeconds
                        }).ToList()
            })
            .ToListAsync();

        return Ok(history);
    }

    private async Task<List<string>> GetDistinctValues(Func<Zest.Api.Models.Exercise, string> selectorEn, Func<Zest.Api.Models.Exercise, string> selectorHu, string lang)
    {
        var exercises = await _context.Exercises.ToListAsync();

        var selector = lang == "hu" ? selectorHu : selectorEn;

        return exercises
            .Select(selector)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct()
            .OrderBy(x => x)
            .ToList();
    }

    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories([FromQuery] string lang = "hu")
    {
        var values = await GetDistinctValues(e => e.Category, e => e.CategoryHu, lang);
        return Ok(values);
    }

    [HttpGet("equipment")]
    public async Task<IActionResult> GetEquipment([FromQuery] string lang = "hu")
    {
        var values = await GetDistinctValues(e => e.Equipment, e => e.EquipmentHu, lang);
        return Ok(values);
    }

    [HttpGet("forces")]
    public async Task<IActionResult> GetForces([FromQuery] string lang = "hu")
    {
        var values = await GetDistinctValues(e => e.Force, e => e.ForceHu ?? e.Force, lang);
        return Ok(values);
    }

    [HttpGet("levels")]
    public async Task<IActionResult> GetLevels([FromQuery] string lang = "hu")
    {
        var values = await GetDistinctValues(e => e.Level, e => e.LevelHu, lang);
        return Ok(values);
    }

    [HttpGet("mechanics")]
    public async Task<IActionResult> GetMechanics([FromQuery] string lang = "hu")
    {
        var values = await GetDistinctValues(e => e.Mechanic, e => e.MechanicHu, lang);
        return Ok(values);
    }
}

public class AddUserWorkoutRequest
{
    public int UserId { get; set; }
    public string? WorkoutName { get; set; }
    public string? CustomName { get; set; }
    public DateTime? Date { get; set; }
    public int DurationMinutes { get; set; }
    public int CaloriesBurnt { get; set; }
    public int TotalVolume { get; set; }
    public List<WorkoutExerciseDto> Exercises { get; set; }
    public bool IsCustom { get; set; }
}

public class AddExerciseRequest
{
    public string Name { get; set; }
    public string? Force { get; set; }
    public string? Equipment { get; set; } = string.Empty;
    public List<string> PrimaryMuscles { get; set; } = new();
    public List<string> SecondaryMuscles { get; set; } = new();
    public string Lang { get; set; } = "hu";
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
    public double? Distance { get; set; }
    public int? DurationSeconds { get; set; }
    public bool IsCompleted { get; set; }
}