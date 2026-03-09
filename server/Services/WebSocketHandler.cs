using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Collections.Concurrent;
using Zest.Api.Data;
using Zest.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace ZestApi.Services;

public class WebSocketMessage
{
    public string Type { get; set; } = string.Empty;
    public JsonElement Data { get; set; }
}

public class WorkoutGameState
{
    public string SessionId { get; set; } = string.Empty;
    public string Status { get; set; } = "Lobby";
    public int CurrentExerciseIndex { get; set; } = 0;
    public int CurrentPlayerIndex { get; set; } = 0;
    public int HostId { get; set; } = 0;

    public List<WorkoutPlayer> Players { get; set; } = new();
    public List<WorkoutStat> Stats { get; set; } = new();
    public List<int> ExerciseIds { get; set; } = new();
}

public class WorkoutPlayer
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string? ProfilePicture { get; set; }
    public bool IsDisconnected { get; set; } = false;
    public bool IsDoneWithExercise { get; set; } = false;
}

public class WorkoutStat
{
    public int UserId { get; set; }
    public int ExerciseId { get; set; }
    public List<SetStat> Sets { get; set; } = new();
}

public class SetStat
{
    public int SetIndex { get; set; }
    public double Weight { get; set; }
    public int Reps { get; set; }
}


public class WebSocketHandler
{
    private readonly ConcurrentDictionary<string, List<WebSocket>> _sessions = new();
    private readonly ConcurrentDictionary<WebSocket, int> _socketUsers = new();
    private readonly ConcurrentDictionary<string, WorkoutGameState> _gameStates = new();
    private readonly IServiceProvider _serviceProvider;

    public WebSocketHandler(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task HandleConnection(string sessionId, int userId, WebSocket webSocket)
    {
        _sessions.AddOrUpdate(sessionId,
            key => new List<WebSocket> { webSocket },
            (key, list) => { lock (list) { list.Add(webSocket); } return list; });

        _socketUsers[webSocket] = userId;

        if (_gameStates.TryGetValue(sessionId, out var state))
        {
            var player = state.Players.FirstOrDefault(p => p.UserId == userId);
            if (player != null)
            {
                player.IsDisconnected = false;
                await BroadcastGameState(sessionId, "sync-workout-state", state);
            }
        }

        await SyncExercisesToSocket(sessionId, webSocket);

        var buffer = new byte[1024 * 8];
        try
        {
            var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            while (!result.CloseStatus.HasValue)
            {
                var messageString = Encoding.UTF8.GetString(buffer, 0, result.Count);
                await ProcessMessage(sessionId, userId, messageString);
                result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"WebSocket Hiba: {ex.Message}");
        }
        finally
        {
            await HandleDisconnect(sessionId, userId, webSocket);
        }
    }

    private async Task HandleDisconnect(string sessionId, int userId, WebSocket webSocket)
    {
        if (_sessions.TryGetValue(sessionId, out var list))
        {
            lock (list) { list.Remove(webSocket); }
            if (list.Count == 0) _sessions.TryRemove(sessionId, out _);
        }
        _socketUsers.TryRemove(webSocket, out _);

        if (_gameStates.TryGetValue(sessionId, out var state) && state.Status == "Running")
        {
            var player = state.Players.FirstOrDefault(p => p.UserId == userId);
            if (player != null)
            {
                player.IsDisconnected = true;

                int activePlayersCount = state.Players.Count(p => !p.IsDisconnected);
                if (activePlayersCount == 0)
                {
                    return;
                }

                if (state.Players[state.CurrentPlayerIndex].UserId == userId)
                {
                    await AdvanceTurn(sessionId, state);
                }
                else
                {
                    await BroadcastGameState(sessionId, "sync-workout-state", state);
                }
            }
        }

        if (webSocket.State == WebSocketState.Open || webSocket.State == WebSocketState.CloseReceived)
            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed", CancellationToken.None);
    }

    private async Task ProcessMessage(string sessionId, int senderUserId, string messageString)
    {
        try
        {
            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            var message = JsonSerializer.Deserialize<WebSocketMessage>(messageString, options);
            if (message == null) return;

            switch (message.Type)
            {
                case "add-exercise":
                    await HandleAddExercise(sessionId, message.Data);
                    break;
                case "remove-exercise":
                    await HandleRemoveExercise(sessionId, message.Data);
                    break;
                case "reorder-exercises":
                    await HandleReorderExercises(sessionId, message.Data);
                    break;
                case "start-shared-workout":
                    await StartSharedWorkout(sessionId);
                    break;
                case "end-turn":
                    await EndTurn(sessionId, senderUserId, message.Data);
                    break;
                case "skip-player":
                    await SkipPlayer(sessionId);
                    break;
                case "end-shared-workout":
                    await EndSharedWorkout(sessionId);
                    break;
                case "leave-shared-workout":
                    await LeaveSharedWorkout(sessionId, senderUserId);
                    break;
                case "get-workout-state":
                    await SendCurrentStateToUser(sessionId, senderUserId);
                    break;
                case "get-exercises":
                    await SyncExercisesToUser(sessionId, senderUserId);
                    break;
            }
        }
        catch (Exception e)
        {
            Console.WriteLine($"Hiba a JSON feldolgozásakor: {e.Message}");
        }
    }

    private async Task StartSharedWorkout(string sessionId)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var participants = await context.SessionParticipants
            .Where(sp => sp.SessionId == sessionId)
            .Include(sp => sp.User)
            .OrderBy(sp => sp.Id)
            .ToListAsync();

        var exercises = await context.SharedSessionExercises
            .Where(s => s.SessionId == sessionId)
            .OrderBy(s => s.OrderIndex)
            .Select(s => s.ExerciseId)
            .ToListAsync();

        if (exercises.Count == 0 || participants.Count == 0) return;

        var gameState = new WorkoutGameState
        {
            SessionId = sessionId,
            Status = "Running",
            CurrentPlayerIndex = 0,
            CurrentExerciseIndex = 0,
            HostId = participants.FirstOrDefault()?.UserId ?? 0,
            ExerciseIds = exercises,
            Players = participants.Select(p => new WorkoutPlayer
            {
                UserId = p.UserId,
                UserName = p.User.UserName,
                ProfilePicture = p.User.ProfilePicture,
                IsDisconnected = false
            }).ToList()
        };

        _gameStates[sessionId] = gameState;

        await BroadcastGameState(sessionId, "workout-started", gameState);
    }

    private async Task EndTurn(string sessionId, int userId, JsonElement data)
    {
        if (!_gameStates.TryGetValue(sessionId, out var state) || state.Status != "Running") return;

        if (state.Players[state.CurrentPlayerIndex].UserId != userId) return;

        try
        {
            var doc = JsonDocument.Parse(data.GetRawText());
            bool finishExercise = false;

            if (doc.RootElement.TryGetProperty("finishExercise", out var feProp))
            {
                finishExercise = feProp.GetBoolean();
            }

            List<SetStat> sets = new();
            if (doc.RootElement.TryGetProperty("sets", out var setsProp))
            {
                sets = JsonSerializer.Deserialize<List<SetStat>>(setsProp.GetRawText(), new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }) ?? new List<SetStat>();
            }

            var player = state.Players.FirstOrDefault(p => p.UserId == userId);
            if (player != null && finishExercise)
            {
                player.IsDoneWithExercise = true;
            }

            var stat = state.Stats.FirstOrDefault(s => s.UserId == userId && s.ExerciseId == state.ExerciseIds[state.CurrentExerciseIndex]);
            if (stat == null)
            {
                stat = new WorkoutStat { UserId = userId, ExerciseId = state.ExerciseIds[state.CurrentExerciseIndex] };
                state.Stats.Add(stat);
            }
            stat.Sets = sets;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Hiba a kör befejezésekor: {ex.Message}");
        }

        await AdvanceTurn(sessionId, state);
    }

    private async Task SkipPlayer(string sessionId)
    {
        if (_gameStates.TryGetValue(sessionId, out var state) && state.Status == "Running")
        {
            await AdvanceTurn(sessionId, state);
        }
    }

    private async Task AdvanceTurn(string sessionId, WorkoutGameState state)
    {
        bool allDoneWithExercise = state.Players.All(p => p.IsDisconnected || p.IsDoneWithExercise);
        bool isWorkoutFinished = false;

        if (allDoneWithExercise)
        {
            state.CurrentExerciseIndex++;
            state.CurrentPlayerIndex = 0;

            foreach (var p in state.Players)
            {
                p.IsDoneWithExercise = false;
            }

            if (state.CurrentExerciseIndex >= state.ExerciseIds.Count)
            {
                state.Status = "Finished";
                isWorkoutFinished = true;
            }
            else
            {
                while (state.CurrentPlayerIndex < state.Players.Count && state.Players[state.CurrentPlayerIndex].IsDisconnected)
                {
                    state.CurrentPlayerIndex++;
                }
                if (state.CurrentPlayerIndex >= state.Players.Count)
                {
                    state.Status = "Finished";
                    isWorkoutFinished = true;
                }
            }
        }
        else
        {
            int loopGuard = 0;
            do
            {
                state.CurrentPlayerIndex++;
                if (state.CurrentPlayerIndex >= state.Players.Count)
                {
                    state.CurrentPlayerIndex = 0;
                }

                loopGuard++;
                if (loopGuard > state.Players.Count) break;

            } while (state.Players[state.CurrentPlayerIndex].IsDisconnected || state.Players[state.CurrentPlayerIndex].IsDoneWithExercise);
        }

        if (isWorkoutFinished)
        {
            await BroadcastGameState(sessionId, "workout-finished", state);
            _gameStates.TryRemove(sessionId, out _);
        }
        else
        {
            await BroadcastGameState(sessionId, "sync-workout-state", state);
        }
    }

    private async Task BroadcastGameState(string sessionId, string messageType, WorkoutGameState state)
    {
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var message = JsonSerializer.Serialize(new { type = messageType, data = state }, options);
        await BroadcastToSession(sessionId, message);
    }

    public async Task BroadcastToSession(string sessionId, string message)
    {
        if (_sessions.TryGetValue(sessionId, out var list))
        {
            var buffer = Encoding.UTF8.GetBytes(message);
            List<WebSocket> socketsCopy;
            lock (list) { socketsCopy = new List<WebSocket>(list); }

            foreach (var socket in socketsCopy)
            {
                if (socket.State == WebSocketState.Open)
                    await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
            }
        }
    }

    private async Task HandleAddExercise(string sessionId, JsonElement data)
    {
        if (data.TryGetProperty("exerciseId", out var idProp))
        {
            int exerciseId = idProp.GetInt32();

            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

            var session = await context.SharedWorkoutSessions.Include(s => s.Exercises).FirstOrDefaultAsync(s => s.SessionId == sessionId);
            if (session != null)
            {
                context.SharedSessionExercises.Add(new SharedSessionExercises
                {
                    SessionId = sessionId,
                    ExerciseId = exerciseId,
                    OrderIndex = session.Exercises.Count + 1
                });
                await context.SaveChangesAsync();

                await BroadcastSyncExercises(sessionId);
            }
        }
    }

    private async Task HandleRemoveExercise(string sessionId, JsonElement data)
    {
        if (data.TryGetProperty("exerciseId", out var idProp))
        {
            int exerciseId = idProp.GetInt32();

            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

            var exerciseToRemove = await context.SharedSessionExercises
                .FirstOrDefaultAsync(s => s.SessionId == sessionId && s.ExerciseId == exerciseId);

            if (exerciseToRemove != null)
            {
                context.SharedSessionExercises.Remove(exerciseToRemove);
                await context.SaveChangesAsync();

                await BroadcastSyncExercises(sessionId);
            }
        }
    }

    private async Task HandleReorderExercises(string sessionId, JsonElement data)
    {
        if (data.TryGetProperty("orderedIds", out var idsProp) && idsProp.ValueKind == JsonValueKind.Array)
        {
            var orderedIds = idsProp.EnumerateArray().Select(e => e.GetInt32()).ToList();

            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

            var sessionExercises = await context.SharedSessionExercises
                .Where(s => s.SessionId == sessionId)
                .ToListAsync();

            var unassignedExercises = sessionExercises.ToList();

            for (int i = 0; i < orderedIds.Count; i++)
            {
                int exId = orderedIds[i];
                var matchingItem = unassignedExercises.FirstOrDefault(x => x.ExerciseId == exId);

                if (matchingItem != null)
                {
                    matchingItem.OrderIndex = i + 1;
                    unassignedExercises.Remove(matchingItem);
                }
            }

            await context.SaveChangesAsync();

            await BroadcastSyncExercises(sessionId);
        }
    }

    private async Task SyncExercisesToSocket(string sessionId, WebSocket socket)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var exercises = await context.SharedSessionExercises
            .Where(s => s.SessionId == sessionId)
            .OrderBy(s => s.OrderIndex)
            .Select(s => s.Exercise)
            .ToListAsync();

        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            ReferenceHandler = ReferenceHandler.IgnoreCycles
        };

        var message = JsonSerializer.Serialize(new { type = "sync-exercises", data = exercises }, options);
        var buffer = Encoding.UTF8.GetBytes(message);
        await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
    }

    private async Task BroadcastSyncExercises(string sessionId)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var exercises = await context.SharedSessionExercises
            .Where(s => s.SessionId == sessionId)
            .OrderBy(s => s.OrderIndex)
            .Select(s => s.Exercise)
            .ToListAsync();

        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            ReferenceHandler = ReferenceHandler.IgnoreCycles
        };

        var message = JsonSerializer.Serialize(new { type = "sync-exercises", data = exercises }, options);
        await BroadcastToSession(sessionId, message);
    }

    private async Task SendCurrentStateToUser(string sessionId, int userId)
    {
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        if (_gameStates.TryGetValue(sessionId, out var state))
        {
            var msg = JsonSerializer.Serialize(new { type = "sync-workout-state", data = state }, options);
            await SendToSingleUser(sessionId, userId, msg);
        }
        else
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();
            var sessionExists = await context.SharedWorkoutSessions.AnyAsync(s => s.SessionId == sessionId);

            if (sessionExists)
            {
                var lobbyState = new WorkoutGameState { SessionId = sessionId, Status = "Lobby" };
                var msg = JsonSerializer.Serialize(new { type = "sync-workout-state", data = lobbyState }, options);
                await SendToSingleUser(sessionId, userId, msg);
            }
            else
            {
                var msg = JsonSerializer.Serialize(new { type = "session-ended" }, options);
                await SendToSingleUser(sessionId, userId, msg);
            }
        }
    }

    private async Task SendToSingleUser(string sessionId, int userId, string message)
    {
        if (_sessions.TryGetValue(sessionId, out var list))
        {
            var socket = list.FirstOrDefault(x => _socketUsers.TryGetValue(x, out int uid) && uid == userId);
            if (socket != null && socket.State == WebSocketState.Open)
            {
                var buffer = Encoding.UTF8.GetBytes(message);
                await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
            }
        }
    }

    private async Task EndSharedWorkout(string sessionId)
    {
        _gameStates.TryRemove(sessionId, out _);

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        await BroadcastToSession(sessionId, JsonSerializer.Serialize(new { type = "session-ended" }, options));

        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();
        var session = await context.SharedWorkoutSessions.FirstOrDefaultAsync(s => s.SessionId == sessionId);
        if (session != null)
        {
            context.SharedWorkoutSessions.Remove(session);
            await context.SaveChangesAsync();
        }
    }

    private async Task LeaveSharedWorkout(string sessionId, int userId)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var participant = await context.SessionParticipants.FirstOrDefaultAsync(p => p.SessionId == sessionId && p.UserId == userId);
        if (participant != null)
        {
            context.SessionParticipants.Remove(participant);
            await context.SaveChangesAsync();
        }

        var nextParticipant = await context.SessionParticipants
            .Where(p => p.SessionId == sessionId)
            .OrderBy(p => p.Id)
            .FirstOrDefaultAsync();

        var session = await context.SharedWorkoutSessions.FirstOrDefaultAsync(s => s.SessionId == sessionId);
        if (session != null && session.HostId == userId)
        {
            if (nextParticipant != null)
            {
                session.HostId = nextParticipant.UserId;
                nextParticipant.Role = Role.Host;
                await context.SaveChangesAsync();
            }
            else
            {
                context.SharedWorkoutSessions.Remove(session);
                await context.SaveChangesAsync();
            }
        }

        if (_gameStates.TryGetValue(sessionId, out var state))
        {
            var player = state.Players.FirstOrDefault(p => p.UserId == userId);
            if (player != null)
            {
                state.Players.Remove(player);
                if (state.Players.Count > 0)
                {
                    if (state.HostId == userId || state.HostId == 0)
                    {
                        if (nextParticipant != null)
                        {
                            state.HostId = nextParticipant.UserId;

                            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
                            var msg = JsonSerializer.Serialize(new { type = "promoted-to-host" }, options);
                            await SendToSingleUser(sessionId, state.HostId, msg);
                        }
                    }

                    if (state.CurrentPlayerIndex >= state.Players.Count)
                    {
                        state.CurrentPlayerIndex = 0;
                    }
                    await BroadcastGameState(sessionId, "sync-workout-state", state);
                }
                else
                {
                    await EndSharedWorkout(sessionId);
                }
            }
        }
        else
        {
            if (nextParticipant != null && session != null && session.HostId == nextParticipant.UserId)
            {
                var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
                var msg = JsonSerializer.Serialize(new { type = "promoted-to-host" }, options);
                await SendToSingleUser(sessionId, nextParticipant.UserId, msg);
            }
        }
    }

    private async Task SyncExercisesToUser(string sessionId, int userId)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var exercises = await context.SharedSessionExercises
            .Where(s => s.SessionId == sessionId)
            .OrderBy(s => s.OrderIndex)
            .Select(s => s.Exercise)
            .ToListAsync();

        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            ReferenceHandler = ReferenceHandler.IgnoreCycles
        };

        var message = JsonSerializer.Serialize(new { type = "sync-exercises", data = exercises }, options);

        await SendToSingleUser(sessionId, userId, message);
    }
}