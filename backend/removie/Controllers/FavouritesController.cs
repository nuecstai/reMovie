using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using removie.Data;
using Microsoft.EntityFrameworkCore;
using removie.Models;

[ApiController]
[Route("api/user")]
public class FavouritesController : ControllerBase
{
    private readonly MovieReviewContext _context;
    private readonly IConfiguration _configuration;

    public FavouritesController(MovieReviewContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }


    [Authorize]
    [HttpPost("add-favourite")]
    public async Task<IActionResult> AddFavorite([FromBody] FavoriteMovieRequest request)
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier); // Get the username
            var user = await _context.Users.Include(u => u.FavoriteMovies).SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return Unauthorized(new { message = "User not found." });

            // Check if movie already exists in the database by TMDB Movie ID
            var movie = await _context.Movies.SingleOrDefaultAsync(m => m.TmdbMovieId == request.MovieId);

            if (movie == null)
            {
                // If movie does not exist in the database, add it
                movie = new Movie { TmdbMovieId = request.MovieId };
                await _context.Movies.AddAsync(movie);
                await _context.SaveChangesAsync();
            }

            // Check if the movie is already in the user's favorites
            if (user.FavoriteMovies.Any(fm => fm.TmdbMovieId == request.MovieId))
            {
                return BadRequest(new { message = "Movie is already in your favorites." });
            }

            // Add movie to user's favorites
            user.FavoriteMovies.Add(movie);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Movie added to favorites!" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }


    [Authorize]
    [HttpGet("favourites")]
    public async Task<IActionResult> GetFavourites()
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier); // Get the username from token

            if (string.IsNullOrEmpty(username))
            {
                return Unauthorized(new { message = "Invalid user. Username not found in token." });
            }

            var user = await _context.Users
                .Include(u => u.FavoriteMovies) // Include FavoriteMovies navigation property
                .ThenInclude(fm => fm.UsersWhoFavorited) // Ensure we also load the related 'Users' if needed
                .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
            {
                return Unauthorized(new { message = "User not found." });
            }

            // Select only TmdbMovieId from the FavoriteMovies list
            var favoriteMovies = user.FavoriteMovies.Select(fm => new
            {
                fm.TmdbMovieId, // Only selecting the TmdbMovieId here
            }).ToList();

            // Return an empty array with 200 OK if no favorite movies
            if (!favoriteMovies.Any())
            {
                return Ok(new List<object>()); // Return an empty list with 200 OK
            }

            return Ok(favoriteMovies);
        }
        catch (Exception ex)
        {
            // Log exception details for better debugging
            Console.WriteLine($"Error: {ex.Message}\n{ex.StackTrace}");
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }


    [Authorize]
    [HttpPost("remove-favourite")]
    public async Task<IActionResult> RemoveFavorite([FromBody] FavoriteMovieRequest request)
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier); // Get the username from the JWT token
            var user = await _context.Users.Include(u => u.FavoriteMovies)
                                           .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return Unauthorized(new { message = "User not found." });

            // Find the movie in the user's favorites
            var movie = user.FavoriteMovies.SingleOrDefault(m => m.TmdbMovieId == request.MovieId);

            if (movie == null)
            {
                return NotFound(new { message = "Movie not found in favorites." });
            }

            // Remove the movie from the user's favorites
            user.FavoriteMovies.Remove(movie);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Movie removed from favorites!" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }

}

public class FavoriteMovieRequest
{
    public int MovieId { get; set; }
}
