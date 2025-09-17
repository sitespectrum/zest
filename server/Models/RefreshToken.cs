using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class RefreshToken
{
    [Key]
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Token { get; set; } = "";
    public DateTime RefreshTokenExpiryTime { get; set; }
}