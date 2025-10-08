using Microsoft.EntityFrameworkCore;
using Zest.Api.Models;

namespace Zest.Api.Data;

public class ZestDbContext : DbContext
{
    public ZestDbContext(DbContextOptions<ZestDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Workout> Workouts { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
    public DbSet<Meals> Meals { get; set; }
    public DbSet<UserMeal> UserMeals { get; set; }

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

        modelBuilder.Entity<UserMeal>()
            .HasOne(um => um.User)
            .WithMany(u => u.UserMeals)
            .HasForeignKey(um => um.UserId);

        modelBuilder.Entity<UserMeal>()
            .HasOne(um => um.Meal)
            .WithMany()
            .HasForeignKey(um => um.FoodId);

        modelBuilder.Entity<UserMeal>()
            .Property(um => um.MealName)
            .HasConversion<string>();

        modelBuilder.Entity<UserMeal>()
            .HasOne(um => um.Meal)
            .WithMany()
            .HasForeignKey(um => um.FoodId)
            .HasPrincipalKey(m => m.FoodId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
