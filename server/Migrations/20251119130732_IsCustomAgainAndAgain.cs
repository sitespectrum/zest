using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class IsCustomAgainAndAgain : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsCustom",
                table: "Meals");

            migrationBuilder.AddColumn<bool>(
                name: "IsCustom",
                table: "UserMeals",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsCustom",
                table: "UserMeals");

            migrationBuilder.AddColumn<bool>(
                name: "IsCustom",
                table: "Meals",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }
    }
}
