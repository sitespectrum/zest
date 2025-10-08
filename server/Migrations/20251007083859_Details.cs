using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class Details : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "UserMealId",
                table: "Meals");

            migrationBuilder.AddColumn<double>(
                name: "TotalCalories",
                table: "UserMeals",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "TotalCarbs",
                table: "UserMeals",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "TotalFat",
                table: "UserMeals",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "TotalProtein",
                table: "UserMeals",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TotalCalories",
                table: "UserMeals");

            migrationBuilder.DropColumn(
                name: "TotalCarbs",
                table: "UserMeals");

            migrationBuilder.DropColumn(
                name: "TotalFat",
                table: "UserMeals");

            migrationBuilder.DropColumn(
                name: "TotalProtein",
                table: "UserMeals");

            migrationBuilder.AddColumn<int>(
                name: "UserMealId",
                table: "Meals",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);
        }
    }
}
