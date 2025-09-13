using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class Workout
{
    [Key]
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Type { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public int CaloriesBurned { get; set; }
    public DateTime Date { get; set; } = DateTime.UtcNow;
}
