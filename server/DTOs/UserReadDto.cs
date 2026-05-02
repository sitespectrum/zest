namespace ZestAPI.DTOs;

public record UserReadDto
{
    public int Id { get; init; }
    public string UserName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public int Height { get; init; }
    public int Weight { get; init; }
    public DateTime Birth { get; init; }
    public string Gender { get; init; } = string.Empty;
    public string Goal { get; init; } = string.Empty;
    public string Activity { get; init; } = string.Empty;
    public double CalorieGoal { get; init; }
    public double ProteinGoal { get; init; }
    public double CarbsGoal { get; init; }
    public double FatGoal { get; init; }
    public string? ProfilePicture { get; init; }
    public bool HasLogged { get; init; }
}