using System.ComponentModel.DataAnnotations;

namespace ZestAPI.Models;

public class SharedMeals
{
    [Key]
    public string Id { get; set; } = "";
    public string JsonData { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}