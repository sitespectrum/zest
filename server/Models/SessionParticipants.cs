using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace ZestAPI.Models;

public enum Role
{
    Host,
    Guest
}

public class SessionParticipants
{
    [Key]
    public int Id { get; set; }

    public string SessionId { get; set; } = string.Empty;

    [ForeignKey("SessionId")]
    [JsonIgnore]
    public SharedWorkoutSession? Session { get; set; }

    public int UserId { get; set; }

    [ForeignKey("UserId")]
    public User? User { get; set; }

    public Role Role { get; set; }

    public bool IsReady { get; set; } = false;
}