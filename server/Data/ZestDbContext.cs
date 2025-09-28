using Microsoft.EntityFrameworkCore;
using Zest.Api.Models;

namespace Zest.Api.Data;

public class ZestDbContext : DbContext
{
    public ZestDbContext(DbContextOptions<ZestDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Workout> Workouts { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .Entity<User>()
            .Property(u => u.Gender)
            .HasConversion<string>();

        modelBuilder.Entity<User>()
            .Property(u => u.Goal)
            .HasConversion(
                v => v.ToString(),
                v => Enum.Parse<Goal>(v));
    }
}
