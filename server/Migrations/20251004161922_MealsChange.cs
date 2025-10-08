using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class MealsChange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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

            migrationBuilder.AlterColumn<string>(
                name: "FoodId",
                table: "UserMeals",
                type: "TEXT",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "INTEGER");

            migrationBuilder.AlterColumn<string>(
                name: "FoodId",
                table: "Meals",
                type: "TEXT",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "INTEGER")
                .OldAnnotation("Sqlite:Autoincrement", true);

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
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

            migrationBuilder.AlterColumn<int>(
                name: "FoodId",
                table: "UserMeals",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "FoodId",
                table: "Meals",
                type: "INTEGER",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "TEXT")
                .Annotation("Sqlite:Autoincrement", true);

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
