namespace ZestAPI.DTOs;

public record UserPatchDto
{
    public string? UserName { get; init; }
    public int? Height { get; init; }
    public int? Weight { get; init; }
    public DateTime? Birth { get; init; }
    public string? Gender { get; init; }
    public string? Goal { get; init; }
    public string? Activity { get; init; }
    public double? CalorieGoal { get; init; }
    public double? ProteinGoal { get; init; }
    public double? CarbsGoal { get; init; }
    public double? FatGoal { get; init; }
    public string? ProfilePicture { get; init; }
}