using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class keychange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserMeals",
                table: "UserMeals");

            migrationBuilder.DropIndex(
                name: "IX_UserMeals_FoodId",
                table: "UserMeals");

            migrationBuilder.AlterColumn<string>(
                name: "FoodId",
                table: "UserMeals",
                type: "TEXT",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "UserMeals",
                type: "INTEGER",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "INTEGER")
                .OldAnnotation("Sqlite:Autoincrement", true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserMeals",
                table: "UserMeals",
                column: "FoodId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserMeals",
                table: "UserMeals");

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "UserMeals",
                type: "INTEGER",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "INTEGER")
                .Annotation("Sqlite:Autoincrement", true);

            migrationBuilder.AlterColumn<string>(
                name: "FoodId",
                table: "UserMeals",
                type: "TEXT",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "TEXT");

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserMeals",
                table: "UserMeals",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_UserMeals_FoodId",
                table: "UserMeals",
                column: "FoodId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserMeals_Meals_FoodId",
                table: "UserMeals",
                column: "FoodId",
                principalTable: "Meals",
                principalColumn: "FoodId");
        }
    }
}
