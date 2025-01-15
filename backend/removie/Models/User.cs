namespace removie.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string PasswordHash { get; set; }
        public bool IsAdmin { get; set; } = false;

        // Navigation property for favorite movies
        public List<Movie> FavoriteMovies { get; set; } = new List<Movie>();

        // Navigation property for watchlist movies
        public List<Movie> WatchlistMovies { get; set; } = new List<Movie>();
    }
}
