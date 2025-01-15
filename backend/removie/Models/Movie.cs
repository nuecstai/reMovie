using removie.Models;

public class Movie
{
    public int Id { get; set; } // Internal DB ID
    public int TmdbMovieId { get; set; } // TMDB Movie ID

    // Navigation property for the relationship with User (FavoriteMovies)
    public List<User> UsersWhoFavorited { get; set; } = new List<User>();

    // Navigation property for the relationship with User (WatchlistMovies)
    public List<User> UsersWhoAddedToWatchlist { get; set; } = new List<User>();
}
