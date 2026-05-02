using ZestAPI.DTOs;
using ZestAPI.Models;

namespace ZestAPI.Extensions;

public static class UserMappingExtensions
{
    public static UserReadDto ToReadDto(this User user) => new()
    {
        Id = user.Id,
        UserName = user.UserName,
        Email = user.Email,
        Height = user.Height,
        Weight = user.Weight,
        Birth = user.Birth,
        Gender = user.Gender.ToString(),
        Goal = user.Goal.ToString(),
        Activity = user.Activity.ToString(),
        CalorieGoal = user.CalorieGoal,
        ProteinGoal = user.ProteinGoal,
        CarbsGoal = user.CarbsGoal,
        FatGoal = user.FatGoal,
        ProfilePicture = user.ProfilePicture,
        HasLogged = user.HasLogged
    };
}