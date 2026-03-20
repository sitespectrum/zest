using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class FoodUnit
{
    [Key]
    public int Id { get; set; }
    
    public string FoodExternalId { get; set; } = string.Empty; 
    
    public string Name { get; set; } = string.Empty;
    public double Weight { get; set; }
    public string Language { get; set; } = string.Empty;
}