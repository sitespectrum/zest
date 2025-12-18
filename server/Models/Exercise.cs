using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Zest.Api.Models;

public class Exercise
{
    [Key]
    public int Id { get; set; }
    public int WorkoutId { get; set; }

    public string Name { get; set; } = string.Empty;
    public string NameHu { get; set; } = string.Empty;

    public string? Force { get; set; }
    public string? ForceHu { get; set; }

    public string Level { get; set; } = string.Empty;
    public string LevelHu { get; set; } = string.Empty;

    public string? Mechanic { get; set; }
    public string? MechanicHu { get; set; }

    public string Equipment { get; set; } = string.Empty;
    public string EquipmentHu { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;
    public string CategoryHu { get; set; } = string.Empty;

    public List<string> PrimaryMuscles { get; set; } = new();
    public List<string> PrimaryMusclesHu { get; set; } = new();

    public List<string> SecondaryMuscles { get; set; } = new();
    public List<string> SecondaryMusclesHu { get; set; } = new();

    public List<string> Instructions { get; set; } = new();
    public List<string> InstructionsHu { get; set; } = new();

    public List<string> Images { get; set; } = new();
    public double MetValue { get; set; } = 3.5;
}
