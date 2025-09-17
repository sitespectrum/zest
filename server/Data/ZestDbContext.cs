using Microsoft.EntityFrameworkCore;
using Zest.Api.Models;

namespace Zest.Api.Data;

public class ZestDbContext : DbContext
{
    public ZestDbContext(DbContextOptions<ZestDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Workout> Workouts { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }

}

