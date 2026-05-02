using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace ZestAPI.Models;

public class SharedSessionExercises
{
    [Key]
    public int Id { get; set; }

    public string SessionId { get; set; } = string.Empty;
    [ForeignKey("SessionId")]
    [JsonIgnore]
    public SharedWorkoutSession? Session { get; set; }

    public int ExerciseId { get; set; }
    [ForeignKey("ExerciseId")]
    public Exercise? Exercise { get; set; }

    public int OrderIndex { get; set; }
}