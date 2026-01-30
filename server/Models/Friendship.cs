using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Zest.Api.Models;

public enum FriendshipStatus
{
    Pending,
    Accepted,
    Declined
}

public class Friendship
{
    [Key]
    public int Id { get; set; }

    public int RequesterId { get; set; }
    [ForeignKey("RequesterId")]
    public User Requester { get; set; } = null!;

    public int AddresseeId { get; set; }
    [ForeignKey("AddresseeId")]
    public User Addressee { get; set; } = null!;

    public FriendshipStatus Status { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}