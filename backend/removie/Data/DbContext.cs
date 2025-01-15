namespace removie.Data
{
    using Microsoft.EntityFrameworkCore;
    using removie.Models;

    public class MovieReviewContext : DbContext
    {
        public MovieReviewContext(DbContextOptions<MovieReviewContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Movie> Movies { get; set; }
        public DbSet<Review> Reviews { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>().HasData(new User
            {
                Id = 1,
                Username = "admin",
                Email = "admin@removie.com",
                PasswordHash = "123123", // Replace with hashed password
                IsAdmin = true
            });

            // Configure many-to-many relationship between User and Favorite Movies
            modelBuilder.Entity<User>()
                .HasMany(u => u.FavoriteMovies)
                .WithMany(m => m.UsersWhoFavorited)
                .UsingEntity<Dictionary<string, object>>(
                    "FavoriteMovie",
                    j => j.HasOne<Movie>().WithMany().HasForeignKey("MovieId"),
                    j => j.HasOne<User>().WithMany().HasForeignKey("UserId")
                );

            // Configure many-to-many relationship between User and Watchlist Movies
            modelBuilder.Entity<User>()
                .HasMany(u => u.WatchlistMovies)
                .WithMany(m => m.UsersWhoAddedToWatchlist)
                .UsingEntity<Dictionary<string, object>>(
                    "WatchlistMovie",
                    j => j.HasOne<Movie>().WithMany().HasForeignKey("MovieId"),
                    j => j.HasOne<User>().WithMany().HasForeignKey("UserId")
                );

            // Configure Review relationships
            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Movie)
                .WithMany()
                .HasForeignKey(r => r.MovieId)
                .OnDelete(DeleteBehavior.Cascade);
        }

    }
}
