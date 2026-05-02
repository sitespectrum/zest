using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace ZestAPI.Models
{
    public class WorkoutExercise
    {
        [Key]
        public int Id { get; set; }

        public int UserWorkoutId { get; set; }
        [ForeignKey("UserWorkoutId")]
        [JsonIgnore]
        public UserWorkouts? UserWorkout { get; set; }

        public int ExerciseId { get; set; }
        [ForeignKey("ExerciseId")]
        public Exercise? Exercise { get; set; }

        public List<WorkoutSet> Sets { get; set; } = new();
    }
}