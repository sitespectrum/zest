using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Zest.Api.Models;

public class Meals
{
    [Key]
    public string? FoodId { get; set; }
    public string? Name { get; set; }
    public string? Piece { get; set; }
    public int Calories { get; set; }
    public double Proteins { get; set; }
    public double Carbs { get; set; }
    public double Fat { get; set; }
}