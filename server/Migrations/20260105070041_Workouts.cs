using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace server.Migrations
{
    /// <inheritdoc />
    public partial class Workouts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Exercises_UserWorkouts_UserWorkoutsId",
                table: "Exercises");

            migrationBuilder.DropIndex(
                name: "IX_Exercises_UserWorkoutsId",
                table: "Exercises");

            migrationBuilder.DropColumn(
                name: "UserWorkoutsId",
                table: "Exercises");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UserWorkoutsId",
                table: "Exercises",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Exercises_UserWorkoutsId",
                table: "Exercises",
                column: "UserWorkoutsId");

            migrationBuilder.AddForeignKey(
                name: "FK_Exercises_UserWorkouts_UserWorkoutsId",
                table: "Exercises",
                column: "UserWorkoutsId",
                principalTable: "UserWorkouts",
                principalColumn: "Id");
        }
    }
}
