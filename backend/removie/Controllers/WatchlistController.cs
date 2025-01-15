using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using removie.Data;
using removie.Models;
using System.Security.Claims;

[Authorize]
[ApiController]
[Route("api/user")]
public class WatchlistController : ControllerBase
{
    private readonly MovieReviewContext _context;

    public WatchlistController(MovieReviewContext context)
    {
        _context = context;
    }

    [HttpPost("add-watchlist")]
    public async Task<IActionResult> AddToWatchlist([FromBody] FavoriteMovieRequest request)
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _context.Users.Include(u => u.WatchlistMovies)
                                           .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return Unauthorized(new { message = "User not found." });

            var movie = await _context.Movies.SingleOrDefaultAsync(m => m.TmdbMovieId == request.MovieId);
            if (movie == null)
            {
                movie = new Movie { TmdbMovieId = request.MovieId };
                await _context.Movies.AddAsync(movie);
                await _context.SaveChangesAsync();
            }

            if (user.WatchlistMovies.Any(wm => wm.TmdbMovieId == request.MovieId))
                return BadRequest(new { message = "Movie is already in your watchlist." });

            user.WatchlistMovies.Add(movie);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Movie added to watchlist!" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }

    [HttpGet("watchlist")]
    public async Task<IActionResult> GetWatchlist()
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _context.Users.Include(u => u.WatchlistMovies)
                                           .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return Unauthorized(new { message = "User not found." });

            var watchlistMovies = user.WatchlistMovies.Select(wm => new { wm.TmdbMovieId }).ToList();
            return Ok(watchlistMovies);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }

    [HttpPost("remove-watchlist")]
    public async Task<IActionResult> RemoveFromWatchlist([FromBody] FavoriteMovieRequest request)
    {
        try
        {
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _context.Users.Include(u => u.WatchlistMovies)
                                           .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return Unauthorized(new { message = "User not found." });

            var movie = user.WatchlistMovies.SingleOrDefault(m => m.TmdbMovieId == request.MovieId);
            if (movie == null)
                return NotFound(new { message = "Movie not found in watchlist." });

            user.WatchlistMovies.Remove(movie);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Movie removed from watchlist!" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }
}
