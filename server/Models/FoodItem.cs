using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class FoodItem
{
    [Key]
    public int Id { get; set; }
    
    public string ExternalId { get; set; } = string.Empty; 
    public string Name { get; set; } = string.Empty;
    public double Calories { get; set; }
    public double Protein { get; set; }
    public double Carbs { get; set; }
    public double Fat { get; set; }
    public string? Unit { get; set; }
    public string Language { get; set; } = string.Empty;
    public string? Barcode { get; set; }
}