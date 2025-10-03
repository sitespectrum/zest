using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Zest.Api.Models;

public class Meals
{
    [Key]
    public int FoodId { get; set; }
    public string? Name { get; set; }
    public string? Piece { get; set; }
    public int Calories { get; set; }
    public bool Proteins { get; set; }
    public bool Carbs { get; set; }
    public bool Fat { get; set; }
}