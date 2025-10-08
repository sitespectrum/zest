using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class MealNameToString : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals");

            migrationBuilder.AlterColumn<string>(
                name: "MealName",
                table: "UserMeals",
                type: "TEXT",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "INTEGER");

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals");

            migrationBuilder.AlterColumn<int>(
                name: "MealName",
                table: "UserMeals",
                type: "INTEGER",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "TEXT");

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId");
        }
    }
}
