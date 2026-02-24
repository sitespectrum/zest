using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Zest.Api.Models;

public class SharedWorkoutSession
{
    [Key]
    public string? SessionId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int HostId { get; set; }
    [ForeignKey("HostId")]
    public User? Host { get; set; }
    public Status Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsPublic { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public List<SessionParticipants> Participants { get; set; } = new();
    public List<SharedSessionExercises> Exercises { get; set; } = new();
}

public enum Status
{
    Lobby,
    In_Progress,
    Finished
}