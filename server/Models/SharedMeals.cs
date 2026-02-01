using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class SharedMeals
{
    [Key]
    public String Id { get; set; }
    public String JsonData { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}