using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using ZestAPI.Models;

public class UserWorkouts
{
    [Key]
    public int Id { get; set; }
    public int UserId { get; set; }
    [ForeignKey("UserId")]
    public User? User { get; set; }
    public string WorkoutName { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.UtcNow;
    public double TotalLiftedWeight { get; set; }
    public int TotalBurntCalories { get; set; }
    public int DurationMinutes { get; set; }
    public bool IsCustom { get; set; }
    public string? CustomName { get; set; }

    public List<WorkoutExercise> Exercises { get; set; } = new();
}