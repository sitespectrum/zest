using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Collections.Concurrent;
using Zest.Api.Data;
using Zest.Api.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;

namespace ZestApi.Services;

public class WebSocketMessage
{
    public string Type { get; set; } = string.Empty;
    public JsonElement Data { get; set; }
}

public class WebSocketHandler
{
    private readonly ConcurrentDictionary<string, List<WebSocket>> _sessions = new();
    private readonly IServiceProvider _serviceProvider;

    public WebSocketHandler(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public void AddSocket(string sessionId, WebSocket socket)
    {
        _sessions.AddOrUpdate(sessionId,
            key => new List<WebSocket> { socket },
            (key, list) => { lock (list) { list.Add(socket); } return list; });
    }

    public async Task RemoveSocket(string sessionId, WebSocket socket)
    {
        if (_sessions.TryGetValue(sessionId, out var list))
        {
            lock (list) { list.Remove(socket); }
            if (list.Count == 0) _sessions.TryRemove(sessionId, out _);
        }
        await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed", CancellationToken.None);
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

    public async Task HandleConnection(string sessionId, WebSocket webSocket)
    {
        AddSocket(sessionId, webSocket);

        await SyncExercisesToSocket(sessionId, webSocket);

        var buffer = new byte[1024 * 4];
        try
        {
            var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            while (!result.CloseStatus.HasValue)
            {
                var messageString = Encoding.UTF8.GetString(buffer, 0, result.Count);
                await ProcessMessage(sessionId, messageString);

                result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"WebSocket Hiba: {ex.Message}");
        }
        finally
        {
            await RemoveSocket(sessionId, webSocket);
        }
    }

    private async Task ProcessMessage(string sessionId, string messageString)
    {
        try
        {
            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase, ReferenceHandler = ReferenceHandler.IgnoreCycles };
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
                default:
                    Console.WriteLine($"Ismeretlen WS üzenet: {message.Type}");
                    break;
            }
        }
        catch (Exception e)
        {
            Console.WriteLine($"Hiba a JSON feldolgozásakor: {e.Message}");
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

    private async Task BroadcastSyncExercises(string sessionId)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ZestDbContext>();

        var exercises = await context.SharedSessionExercises
            .Where(s => s.SessionId == sessionId)
            .OrderBy(s => s.OrderIndex)
            .Select(s => s.Exercise)
            .ToListAsync();

        var message = JsonSerializer.Serialize(new { type = "sync-exercises", data = exercises }, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        await BroadcastToSession(sessionId, message);
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

        var message = JsonSerializer.Serialize(new { type = "sync-exercises", data = exercises }, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var buffer = Encoding.UTF8.GetBytes(message);
        await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
    }
}