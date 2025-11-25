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

    public MealName MealName { get; set; }
    public int UserId { get; set; }

    public double TotalCalories { get; set; }
    public double TotalProtein { get; set; }
    public double TotalCarbs { get; set; }
    public double TotalFat { get; set; }
    public bool IsCustom { get; set; }
    public string? CustomName { get; set; }

    public DateTime EatenAt { get; set; } = DateTime.Today;

    public User? User { get; set; }

    public List<Meals> Meals { get; set; } = new();
}
