using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Zest.Api.Models;

public enum MealName
{
    Reggeli,
    Ebéd,
    Vacsora,
    Egyéb
}

public class UserMeal
{
    [Key]
    public int Id { get; set; }
    public string? FoodId { get; set; }
    public MealName MealName { get; set; }
    public int UserId { get; set; }
    public double TotalCalories { get; set; }
    public double TotalProtein { get; set; }
    public double TotalCarbs { get; set; }
    public double TotalFat { get; set; }
    public User? User { get; set; }
    [ForeignKey("FoodId")]
    public Meals? Meal { get; set; }
    public DateTime EatenAt { get; set; } = DateTime.UtcNow;
}
