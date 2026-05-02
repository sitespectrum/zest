using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore.Metadata;

namespace ZestAPI.Models;

public class Meals
{
    [Key]
    public int Id { get; set; }
    public string FoodId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Piece { get; set; }
    public int Calories { get; set; }
    public double Proteins { get; set; }
    public double Carbs { get; set; }
    public double Fat { get; set; }
    public int Quantity { get; set; }
    public string? Unit { get; set; }
    public double? BaseWeight { get; set; }

    [ForeignKey("UserMeal")]
    public int UserMealId { get; set; }
    public UserMeal UserMeal { get; set; } = null!;
}