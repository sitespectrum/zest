using System.ComponentModel.DataAnnotations;
using Zest.Api.Models;

public class UserMeal
{
    [Key]
    public int Id { get; set; }

    public int UserId { get; set; }
    public User? User { get; set; }

    public int FoodId { get; set; }
    public Meals? Meal { get; set; }

    public DateTime EatenAt { get; set; } = DateTime.UtcNow;

}
