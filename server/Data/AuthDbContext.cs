using Microsoft.EntityFrameworkCore;
using Zest.Api.Models;

namespace Zest.Api.Data
{
    public class AuthDbContext : DbContext
    {
        public AuthDbContext(DbContextOptions<AuthDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
    }
}
