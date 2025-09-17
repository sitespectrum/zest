using System.ComponentModel.DataAnnotations;

namespace Zest.Api.Models;

public class User
{
    [Key]
    public int Id { get; set; }
    public string UserName { get; set; } = "";
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
}
