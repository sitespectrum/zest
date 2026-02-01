using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zest.Api.Models;
using System.Text.Json;

namespace Zest.Api.Data;

public class ZestDbContext : DbContext
{
    public ZestDbContext(DbContextOptions<ZestDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Exercise> Exercises { get; set; }
    public DbSet<UserWorkouts> UserWorkouts { get; set; }
    public DbSet<WorkoutExercise> WorkoutExercises { get; set; }
    public DbSet<WorkoutSet> WorkoutSets { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
    public DbSet<Meals> Meals { get; set; }
    public DbSet<UserMeal> UserMeals { get; set; }
    public DbSet<SharedWorkouts> SharedWorkouts { get; set; }
    public DbSet<SharedMeals> SharedMeals { get; set; }
    public DbSet<Friendship> Friendships { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var listComparer = new ValueComparer<List<string>>(
                    (c1, c2) => c1.SequenceEqual(c2),
                    c => c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
                    c => c.ToList());

        void ConfigureStringList(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<Exercise> entity,
                                 System.Linq.Expressions.Expression<Func<Exercise, List<string>>> propertyExpression)
        {
            entity.Property(propertyExpression)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions)null),
                    v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions)null) ?? new List<string>())
                .Metadata.SetValueComparer(listComparer);
        }

        // Minden listás mezőre beállítjuk a konverziót
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.Instructions);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.InstructionsHu);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.PrimaryMuscles);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.PrimaryMusclesHu);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.SecondaryMuscles);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.SecondaryMusclesHu);
        ConfigureStringList(modelBuilder.Entity<Exercise>(), e => e.Images);

        modelBuilder
            .Entity<User>()
            .Property(u => u.Gender)
            .HasConversion<string>();

        modelBuilder.Entity<User>()
            .Property(u => u.Goal)
            .HasConversion(
                v => v.ToString(),
                v => Enum.Parse<Goal>(v));

        modelBuilder.Entity<User>()
            .Property(u => u.Activity)
            .HasConversion(
                v => v.ToString(),
                v => Enum.Parse<Activity>(v));

        modelBuilder.Entity<UserMeal>()
            .HasOne(um => um.User)
            .WithMany(u => u.UserMeals)
            .HasForeignKey(um => um.UserId);

        modelBuilder.Entity<UserMeal>()
            .HasMany(um => um.Meals)
            .WithOne(m => m.UserMeal)
            .HasForeignKey(m => m.UserMealId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserMeal>()
            .Property(um => um.MealName)
            .HasConversion<string>();

        modelBuilder.Entity<Friendship>()
            .HasOne(f => f.Requester)
            .WithMany()
            .HasForeignKey(f => f.RequesterId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Friendship>()
            .HasOne(f => f.Addressee)
            .WithMany()
            .HasForeignKey(f => f.AddresseeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
