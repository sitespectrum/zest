using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Zest.Api.Models
{
    public class WorkoutSet
    {
        [Key]
        public int Id { get; set; }

        public int WorkoutId { get; set; }
        
        [ForeignKey("WorkoutId")]
        [JsonIgnore]
        public WorkoutExercise? WorkoutExercise { get; set; }

        public int Reps { get; set; }
        public double? Distance { get; set; }
        public double? DurationSeconds { get; set; }
        public double Weight { get; set; }
        public int Order { get; set; }
        public bool IsCompleted { get; set; } = false;
    }
}