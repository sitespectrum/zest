using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ZestAPI.Data;
using ZestAPI.Models;

namespace ZestAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController(ZestDbContext context, IConfiguration configuration) : ControllerBase
{
    private readonly ZestDbContext _context = context;
    private readonly IConfiguration _configuration = configuration;

    // MODELS

    public record AdminLoginRequest(string Username, string Password);
    public record LoginSuccessResponse(string Token, string Username);

    private string GenerateAdminJwtToken(string username)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.Name, username),
            new(ClaimTypes.Role, "Admin")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? ""));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddDays(7),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(LoginSuccessResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status500InternalServerError)]
    public IActionResult Login([FromBody] AdminLoginRequest request)
    {
        var adminUser = Environment.GetEnvironmentVariable("ADMIN_USERNAME") ?? _configuration["ADMIN_USERNAME"];
        var adminPass = Environment.GetEnvironmentVariable("ADMIN_PASSWORD") ?? _configuration["ADMIN_PASSWORD"];

        if (string.IsNullOrEmpty(adminUser) || string.IsNullOrEmpty(adminPass))
        {
            return StatusCode(500, new ErrorResponse("Szerver hiba: Admin adatok nincsenek beállítva a .env fájlban!"));
        }

        var userMatch = CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(request.Username), Encoding.UTF8.GetBytes(adminUser));
        var passMatch = CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(request.Password), Encoding.UTF8.GetBytes(adminPass));

        if (!userMatch || !passMatch) return Unauthorized(new ErrorResponse("Hibás felhasználónév vagy jelszó!"));

        var adminToken = GenerateAdminJwtToken(adminUser);

        return Ok(new LoginSuccessResponse(adminToken, adminUser));
    }

    // ==========================================
    // --- FELHASZNÁLÓK MODERÁLÁSA ---
    // ==========================================

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .Select(u => new
            {
                u.Id,
                u.UserName,
                u.Email,
                u.Height,
                u.Weight,
                Goal = u.Goal.ToString(),
                Activity = u.Activity.ToString(),
                Gender = u.Gender.ToString(),
                u.Birth,
                u.ProfilePicture
            })
            .ToListAsync();

        return Ok(users);
    }

    // --- FELHASZNÁLÓ RÉSZLETES ADATAI ---
    [HttpGet("users/{id}/details")]
    public async Task<IActionResult> GetUserDetails(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Felhasználó nem található." });

        var friends = await _context.Friendships
            .Where(f => (f.RequesterId == id || f.AddresseeId == id) && f.Status == FriendshipStatus.Accepted)
            .Select(f => f.RequesterId == id ? f.Addressee.UserName : f.Requester.UserName)
            .ToListAsync();

        var recentWorkouts = await _context.UserWorkouts
            .Where(w => w.UserId == id)
            .OrderByDescending(w => w.Date)
            .Take(5)
            .Select(w => new
            {
                w.Id,
                w.WorkoutName,
                w.CustomName,
                w.Date,
                w.DurationMinutes,
                w.TotalBurntCalories
            })
            .ToListAsync();

        var recentMeals = await _context.UserMeals
            .Where(m => m.UserId == id)
            .OrderByDescending(m => m.EatenAt)
            .Take(5)
            .Select(m => new
            {
                m.Id,
                MealName = m.MealName.ToString(),
                m.CustomName,
                m.EatenAt,
                m.TotalCalories,
                m.TotalProtein,
                m.TotalCarbs,
                m.TotalFat
            })
            .ToListAsync();

        var totalWorkouts = await _context.UserWorkouts.CountAsync(w => w.UserId == id);
        var totalMeals = await _context.UserMeals.CountAsync(m => m.UserId == id);

        return Ok(new
        {
            user.Id,
            user.UserName,
            user.Email,
            user.ProfilePicture,
            user.Height,
            user.Weight,
            Gender = user.Gender.ToString(),
            Goal = user.Goal.ToString(),
            Activity = user.Activity.ToString(),
            user.Birth,
            FriendsCount = friends.Count,
            FriendsList = friends,
            TotalWorkouts = totalWorkouts,
            TotalMeals = totalMeals,
            RecentWorkouts = recentWorkouts,
            RecentMeals = recentMeals
        });
    }

    public class AdminUserUpdateRequest
    {
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int Height { get; set; }
        public int Weight { get; set; }
        public string Gender { get; set; } = string.Empty;
        public string Goal { get; set; } = string.Empty;
        public string Activity { get; set; } = string.Empty;
        public DateTime Birth { get; set; }
    }

    [HttpPut("users/{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] AdminUserUpdateRequest request)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Felhasználó nem található." });

        user.UserName = request.UserName;
        user.Email = request.Email;
        user.Height = request.Height;
        user.Weight = request.Weight;
        user.Birth = request.Birth;

        if (Enum.TryParse<Gender>(request.Gender, true, out var parsedGender))
            user.Gender = parsedGender;

        if (Enum.TryParse<Goal>(request.Goal, true, out var parsedGoal))
            user.Goal = parsedGoal;

        if (Enum.TryParse<Activity>(request.Activity, true, out var parsedActivity))
            user.Activity = parsedActivity;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Felhasználó adatai sikeresen frissítve." });
    }

    [HttpDelete("users/{id}/profile-picture")]
    public async Task<IActionResult> RemoveProfilePicture(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Felhasználó nem található." });

        user.ProfilePicture = null;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Profilkép sikeresen törölve." });
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Felhasználó nem található." });

        var friendships = await _context.Friendships.Where(f => f.RequesterId == id || f.AddresseeId == id).ToListAsync();
        _context.Friendships.RemoveRange(friendships);

        var userMeals = await _context.UserMeals.Where(m => m.UserId == id).ToListAsync();
        _context.UserMeals.RemoveRange(userMeals);

        var userWorkouts = await _context.UserWorkouts.Where(w => w.UserId == id).ToListAsync();
        _context.UserWorkouts.RemoveRange(userWorkouts);

        var hostedSessions = await _context.SharedWorkoutSessions.Where(s => s.HostId == id).ToListAsync();
        _context.SharedWorkoutSessions.RemoveRange(hostedSessions);

        var participations = await _context.SessionParticipants.Where(p => p.UserId == id).ToListAsync();
        _context.SessionParticipants.RemoveRange(participations);

        var tokens = await _context.RefreshTokens.Where(t => t.UserId == id).ToListAsync();
        _context.RefreshTokens.RemoveRange(tokens);

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Felhasználó sikeresen törölve." });
    }

    // ==========================================
    // --- GYAKORLATOK MODERÁLÁSA ---
    // ==========================================

    [HttpGet("exercises")]
    public async Task<IActionResult> GetExercises()
    {
        var exercises = await _context.Exercises.ToListAsync();
        return Ok(exercises);
    }

    [HttpPost("exercises")]
    public async Task<IActionResult> CreateExercise([FromBody] Exercise request)
    {
        _context.Exercises.Add(request);
        await _context.SaveChangesAsync();

        return Ok(request);
    }

    [HttpPut("exercises/{id}")]
    public async Task<IActionResult> UpdateExercise(int id, [FromBody] Exercise request)
    {
        var exercise = await _context.Exercises.FindAsync(id);
        if (exercise == null) return NotFound(new { message = "Gyakorlat nem található." });

        exercise.Name = request.Name;
        exercise.NameHu = request.NameHu;
        exercise.Category = request.Category;
        exercise.CategoryHu = request.CategoryHu;
        exercise.Equipment = request.Equipment;
        exercise.EquipmentHu = request.EquipmentHu;
        exercise.Force = request.Force;
        exercise.ForceHu = request.ForceHu;
        exercise.Level = request.Level;
        exercise.LevelHu = request.LevelHu;
        exercise.Mechanic = request.Mechanic;
        exercise.MechanicHu = request.MechanicHu;
        exercise.MetValue = request.MetValue;

        exercise.PrimaryMuscles = request.PrimaryMuscles;
        exercise.PrimaryMusclesHu = request.PrimaryMusclesHu;
        exercise.SecondaryMuscles = request.SecondaryMuscles;
        exercise.SecondaryMusclesHu = request.SecondaryMusclesHu;
        exercise.Instructions = request.Instructions;
        exercise.InstructionsHu = request.InstructionsHu;
        exercise.Images = request.Images;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Gyakorlat sikeresen frissítve." });
    }

    [HttpDelete("exercises/{id}")]
    public async Task<IActionResult> DeleteExercise(int id)
    {
        var exercise = await _context.Exercises.FindAsync(id);
        if (exercise == null) return NotFound(new { message = "Gyakorlat nem található." });

        var workoutExercises = await _context.WorkoutExercises.Where(we => we.ExerciseId == id).ToListAsync();
        _context.WorkoutExercises.RemoveRange(workoutExercises);

        var sharedSessionExercises = await _context.SharedSessionExercises.Where(se => se.ExerciseId == id).ToListAsync();
        _context.SharedSessionExercises.RemoveRange(sharedSessionExercises);

        _context.Exercises.Remove(exercise);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Gyakorlat sikeresen törölve." });
    }

    // ===================================================
    // --- FELHASZNÁLÓI EDZÉSEK MODERÁLÁSA ---
    // ===================================================

    [HttpGet("workouts")]
    public async Task<IActionResult> GetUserWorkouts()
    {
        var workouts = await _context.UserWorkouts
            .Include(w => w.User)
            .Select(w => new
            {
                w.Id,
                w.UserId,
                UserName = w.User != null ? w.User.UserName : "Ismeretlen",
                w.WorkoutName,
                w.CustomName,
                w.Date,
                w.DurationMinutes,
                w.TotalBurntCalories,
                w.IsCustom
            })
            .OrderByDescending(w => w.Date)
            .ToListAsync();

        return Ok(workouts);
    }

    [HttpDelete("workouts/{id}")]
    public async Task<IActionResult> DeleteUserWorkout(int id)
    {
        var workout = await _context.UserWorkouts.FindAsync(id);
        if (workout == null) return NotFound(new { message = "Edzés nem található." });

        var exercises = await _context.WorkoutExercises.Where(e => e.UserWorkoutId == id).ToListAsync();
        _context.WorkoutExercises.RemoveRange(exercises);

        _context.UserWorkouts.Remove(workout);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Edzés sikeresen törölve." });
    }

    // =====================================================
    // --- FELHASZNÁLÓI ÉTKEZÉSEK MODERÁLÁSA ---
    // =====================================================

    [HttpGet("meals")]
    public async Task<IActionResult> GetUserMeals()
    {
        var meals = await _context.UserMeals
            .Include(m => m.User)
            .Select(m => new
            {
                m.Id,
                m.UserId,
                UserName = m.User != null ? m.User.UserName : "Ismeretlen",
                MealName = m.MealName.ToString(),
                m.CustomName,
                m.EatenAt,
                m.TotalCalories,
                m.IsCustom
            })
            .OrderByDescending(m => m.EatenAt)
            .ToListAsync();

        return Ok(meals);
    }

    [HttpDelete("meals/{id}")]
    public async Task<IActionResult> DeleteUserMeal(int id)
    {
        var meal = await _context.UserMeals.FindAsync(id);
        if (meal == null) return NotFound(new { message = "Étkezés nem található." });

        _context.UserMeals.Remove(meal);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Étkezés sikeresen törölve." });
    }

    // =======================================================
    // --- KÖZÖS EDZÉSEK FELÜGYELETE ---
    // =======================================================

    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions()
    {
        var sessions = await _context.SharedWorkoutSessions
            .Include(s => s.Host)
            .Include(s => s.Participants)
            .Select(s => new
            {
                s.SessionId,
                s.Name,
                HostName = s.Host != null ? s.Host.UserName : "Ismeretlen",
                s.IsPublic,
                s.CreatedAt,
                Status = s.Status.ToString(),
                ParticipantCount = s.Participants.Count()
            })
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

        return Ok(sessions);
    }

    [HttpDelete("sessions/{sessionId}")]
    public async Task<IActionResult> DeleteSession(string sessionId)
    {
        var session = await _context.SharedWorkoutSessions.FindAsync(sessionId);
        if (session == null) return NotFound(new { message = "Session nem található." });

        var participations = await _context.SessionParticipants.Where(p => p.SessionId == sessionId).ToListAsync();
        _context.SessionParticipants.RemoveRange(participations);

        var exercises = await _context.SharedSessionExercises.Where(e => e.SessionId == sessionId).ToListAsync();
        _context.SharedSessionExercises.RemoveRange(exercises);

        _context.SharedWorkoutSessions.Remove(session);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Session sikeresen leállítva és törölve." });
    }

    // ==========================================
    // --- DASHBOARD STATISZTIKA ---
    // ==========================================

    [HttpGet("stats")]
    public async Task<IActionResult> GetDashboardStats()
    {
        var today = DateTime.UtcNow.Date;

        var stats = new
        {
            TotalUsers = await _context.Users.CountAsync(),

            TotalWorkouts = await _context.UserWorkouts.CountAsync(),
            TodayWorkouts = await _context.UserWorkouts.CountAsync(w => w.Date >= today),

            TotalMeals = await _context.UserMeals.CountAsync(),
            TodayMeals = await _context.UserMeals.CountAsync(m => m.EatenAt >= today),

            ActiveSessions = await _context.SharedWorkoutSessions.CountAsync(s => s.Status == Status.In_Progress || s.Status == Status.Lobby),

            TotalExercises = await _context.Exercises.CountAsync()
        };

        return Ok(stats);
    }

    // =======================================================
    // --- GLOBÁLIS ÉRTESÍTÉSEK (PUSH NOTIFICATIONS) ---
    // =======================================================

    public class BroadcastNotificationRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
    }

    [HttpPost("notifications/broadcast")]
    public async Task<IActionResult> BroadcastNotification([FromBody] BroadcastNotificationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.Message))
            return BadRequest(new { message = "Cím és üzenet megadása kötelező!" });

        string actualAppId = Environment.GetEnvironmentVariable("ONESIGNAL_APP_ID") ?? _configuration["ONESIGNAL_APP_ID"] ?? "";
        string restApiKey = Environment.GetEnvironmentVariable("ONESIGNAL_REST_API_KEY") ?? _configuration["ONESIGNAL_REST_API_KEY"] ?? "";

        if (string.IsNullOrEmpty(actualAppId) || string.IsNullOrEmpty(restApiKey))
            return StatusCode(500, new { message = "Szerver hiba: OneSignal kulcsok nincsenek beállítva!" });

        var notificationData = new
        {
            app_id = actualAppId,
            included_segments = new[] { "Total Subscriptions" },
            target_channel = "push",
            headings = new { en = request.Title, hu = request.Title },
            contents = new { en = request.Message, hu = request.Message },
            android_accent_color = "FF40FF32",
            small_icon = "ic_stat_onesignal_default"
        };

        using var httpClient = new HttpClient();
        var httpRequest = new HttpRequestMessage(HttpMethod.Post, "https://onesignal.com/api/v1/notifications");
        httpRequest.Headers.Add("Authorization", $"Basic {restApiKey}");
        httpRequest.Headers.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));

        var jsonContent = JsonSerializer.Serialize(notificationData);
        httpRequest.Content = new StringContent(jsonContent, System.Text.Encoding.UTF8, "application/json");

        var response = await httpClient.SendAsync(httpRequest);
        var responseBody = await response.Content.ReadAsStringAsync();

        Console.WriteLine($"OneSignal API Válasz: {responseBody}");

        if (response.IsSuccessStatusCode)
        {
            if (responseBody.Contains("\"recipients\":0"))
            {
                return BadRequest(new { message = "A OneSignal elfogadta a kérést, de 0 embernek küldte ki! (Lehet, hogy épp senki nincs feliratkozva értesítésekre?)" });
            }

            return Ok(new { message = "Értesítés sikeresen kiküldve minden felhasználónak!" });
        }
        else
        {
            Console.WriteLine($"OneSignal Hiba: {responseBody}");
            return StatusCode((int)response.StatusCode, new { message = "Hiba a küldés során", details = responseBody });
        }
    }

    // =======================================================
    // --- GLOBÁLIS EDZÉSTERVEK---
    // =======================================================

    private async Task<int> GetOrCreateZestOfficialUserId()
    {
        var officialUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "official@zest.app");
        if (officialUser == null)
        {
            officialUser = new User
            {
                UserName = "Zest Official",
                Email = "official@zest.app",
                PasswordHash = "LOCKED",
                Gender = Gender.Férfi,
                Activity = Activity.Közepesen_aktív,
                Goal = Goal.Szintentartás,
                Birth = DateTime.UtcNow
            };
            _context.Users.Add(officialUser);
            await _context.SaveChangesAsync();
        }
        return officialUser.Id;
    }

    [HttpGet("templates")]
    public async Task<IActionResult> GetGlobalTemplates()
    {
        int officialId = await GetOrCreateZestOfficialUserId();

        var templates = await _context.UserWorkouts
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Exercise)
            .Include(w => w.Exercises)
                .ThenInclude(e => e.Sets)
            .Where(w => w.UserId == officialId && w.IsCustom == true)
            .OrderByDescending(w => w.Date)
            .Select(w => new
            {
                w.Id,
                w.CustomName,
                w.DurationMinutes,
                w.TotalBurntCalories,
                ExerciseCount = w.Exercises.Count,
                Exercises = w.Exercises.Select(we => new
                {
                    we.ExerciseId,
                    NameHu = we.Exercise != null ? we.Exercise.NameHu : "Ismeretlen",
                    SetsCount = we.Sets.Count
                })
            })
            .ToListAsync();

        return Ok(templates);
    }

    public class AdminWorkoutSetDto
    {
        public double Weight { get; set; }
        public int Reps { get; set; }
    }

    public class AdminWorkoutExerciseDto
    {
        public int ExerciseId { get; set; }
        public List<AdminWorkoutSetDto> Sets { get; set; } = new();
    }

    public class CreateTemplateRequest
    {
        public string CustomName { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public int CaloriesBurnt { get; set; }
        public List<AdminWorkoutExerciseDto> Exercises { get; set; } = new();
    }

    [HttpPost("templates")]
    public async Task<IActionResult> CreateGlobalTemplate([FromBody] CreateTemplateRequest request)
    {
        int officialId = await GetOrCreateZestOfficialUserId();

        var userWorkout = new UserWorkouts
        {
            UserId = officialId,
            CustomName = request.CustomName,
            WorkoutName = request.CustomName,
            Date = DateTime.UtcNow,
            DurationMinutes = request.DurationMinutes,
            TotalBurntCalories = request.CaloriesBurnt,
            TotalLiftedWeight = 0,
            IsCustom = true,
            Exercises = request.Exercises.Select(e => new WorkoutExercise
            {
                ExerciseId = e.ExerciseId,
                Sets = e.Sets.Select((s, index) => new WorkoutSet
                {
                    Weight = s.Weight,
                    Reps = s.Reps,
                    Order = index + 1,
                    IsCompleted = false
                }).ToList()
            }).ToList()
        };

        _context.UserWorkouts.Add(userWorkout);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Hivatalos sablon sikeresen létrehozva." });
    }

    [HttpDelete("templates/{id}")]
    public async Task<IActionResult> DeleteGlobalTemplate(int id)
    {
        int officialId = await GetOrCreateZestOfficialUserId();

        var workout = await _context.UserWorkouts
            .Include(w => w.Exercises)
            .ThenInclude(e => e.Sets)
            .FirstOrDefaultAsync(w => w.Id == id && w.UserId == officialId);

        if (workout == null) return NotFound(new { message = "Sablon nem található." });

        _context.UserWorkouts.Remove(workout);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Sablon sikeresen törölve." });
    }
}