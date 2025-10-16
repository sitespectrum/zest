using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class AddUnitAndWeight : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "BaseWeight",
                table: "Meals",
                type: "REAL",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Unit",
                table: "Meals",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BaseWeight",
                table: "Meals");

            migrationBuilder.DropColumn(
                name: "Unit",
                table: "Meals");
        }
    }
}
