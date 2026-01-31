using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Zest.Api.Models;

public class Exercise
{
    [Key]
    [JsonPropertyName("id")]
    [DatabaseGenerated(DatabaseGeneratedOption.None)]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;
    [JsonPropertyName("name_hu")]
    public string NameHu { get; set; } = string.Empty;

    [JsonPropertyName("force")]
    public string? Force { get; set; }
    [JsonPropertyName("force_hu")]
    public string? ForceHu { get; set; }

    [JsonPropertyName("level")]
    public string Level { get; set; } = string.Empty;
    [JsonPropertyName("level_hu")]
    public string LevelHu { get; set; } = string.Empty;

    [JsonPropertyName("mechanic")]
    public string? Mechanic { get; set; }
    [JsonPropertyName("mechanic_hu")]
    public string? MechanicHu { get; set; }

    [JsonPropertyName("equipment")]
    public string? Equipment { get; set; } = string.Empty;
    [JsonPropertyName("equipment_hu")]
    public string? EquipmentHu { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;
    [JsonPropertyName("category_hu")]
    public string CategoryHu { get; set; } = string.Empty;

    [JsonPropertyName("primaryMuscles")]
    public List<string> PrimaryMuscles { get; set; } = new();
    [JsonPropertyName("primaryMuscles_hu")]
    public List<string> PrimaryMusclesHu { get; set; } = new();

    [JsonPropertyName("secondaryMuscles")]
    public List<string> SecondaryMuscles { get; set; } = new();
    [JsonPropertyName("secondaryMuscles_hu")]
    public List<string> SecondaryMusclesHu { get; set; } = new();

    [JsonPropertyName("instructions")]
    public List<string>? Instructions { get; set; } = new();
    [JsonPropertyName("instructions_hu")]
    public List<string>? InstructionsHu { get; set; } = new();

    [JsonPropertyName("images")]
    public List<string> Images { get; set; } = new();
    public double MetValue { get; set; } = 3.5;
}
