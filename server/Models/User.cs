using System.ComponentModel.DataAnnotations;
using System.Diagnostics;

namespace Zest.Api.Models;

public enum Gender
{
    Férfi,
    Nő
}

public enum Goal
{
    Tömegelés,
    Szintentartás,
    Fogyás
}

public enum Activity
{
    Enyhén_aktív,
    Közepesen_aktív,
    Nagyon_aktív,
    Extrém_aktív
}

public class User
{
    [Key]
    public int Id { get; set; }
    public string UserName { get; set; } = "";
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public int Height { get; set; }
    public int Weight { get; set; }
    public DateTime Birth { get; set; }
    public Gender Gender { get; set; }
    public Goal Goal { get; set; }
    public Activity Activity { get; set; }
    public double CalorieGoal { get; set; }
    public ICollection<UserMeal> UserMeals { get; set; } = new List<UserMeal>();
}
