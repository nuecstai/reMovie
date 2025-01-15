using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using removie.Data;
using Microsoft.EntityFrameworkCore;
using removie.Models;

[ApiController]
[Route("api/review")]
public class ReviewController : ControllerBase
{
    private readonly MovieReviewContext _context;

    public ReviewController(MovieReviewContext context)
    {
        _context = context;
    }

    [Authorize]
    [HttpPost("add")]
    public async Task<IActionResult> AddReview([FromBody] AddReviewRequest request)
    {
        // Validate the review data
        if (request == null || request.Rating < 1 || request.Rating > 5 || string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest(new { message = "Invalid review data." });
        }

        // Retrieve the username from the token claims
        var username = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(username))
        {
            return Unauthorized(new { message = "Invalid user claim in token." });
        }

        // Check if the user exists
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
        if (user == null)
        {
            return NotFound(new { message = "User not found." });
        }

        // Check if the movie exists or add it
        var movie = await _context.Movies.FirstOrDefaultAsync(m => m.TmdbMovieId == request.TmdbMovieId);
        if (movie == null)
        {
            movie = new Movie { TmdbMovieId = request.TmdbMovieId };
            _context.Movies.Add(movie);
            await _context.SaveChangesAsync();
        }

        // Add the review
        var review = new Review
        {
            UserId = user.Id,
            MovieId = movie.Id,
            Content = request.Content,
            Rating = request.Rating
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Review added successfully." });
    }

    [Authorize]
    [HttpDelete("{reviewId}")]
    public async Task<IActionResult> DeleteReview(int reviewId)
    {
        // Retrieve the review from the database
        var review = await _context.Reviews.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound(new { message = "Review not found." });
        }

        // Retrieve the username and admin status from the token
        var username = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var isAdmin = User.IsInRole("Admin");

        // Log the usernames for debugging
        Console.WriteLine($"Review Username: {review.User.Username}, Token Username: {username}, IsAdmin: {isAdmin}");

        // Check if the authenticated user is the owner of the review or an admin
        if (review.User.Username != username && !isAdmin)
        {
            return Unauthorized(new { message = "You are not authorized to delete this review." });
        }

        // Remove the review
        _context.Reviews.Remove(review);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Review deleted successfully." });
    }

    [Authorize]
    [HttpPut("{reviewId}")]
    public async Task<IActionResult> EditReview(int reviewId, [FromBody] EditReviewRequest request)
    {
        // Validate the review data
        if (request == null || request.Rating < 1 || request.Rating > 5 || string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest(new { message = "Invalid review data." });
        }

        // Retrieve the review
        var review = await _context.Reviews.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == reviewId);
        if (review == null)
        {
            return NotFound(new { message = "Review not found." });
        }

        // Retrieve the username from the token
        var username = User.FindFirstValue(ClaimTypes.NameIdentifier);

        // Check if the authenticated user is the owner of the review
        if (review.User.Username != username)
        {
            return Unauthorized(new { message = "You can only edit your own reviews." });
        }

        // Update the review
        review.Content = request.Content;
        review.Rating = request.Rating;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Review updated successfully." });
    }


    [HttpGet("{tmdbMovieId}/reviews")]
    public async Task<IActionResult> GetReviews(int tmdbMovieId)
    {
        var movie = await _context.Movies.FirstOrDefaultAsync(m => m.TmdbMovieId == tmdbMovieId);
        if (movie == null)
        {
            return NotFound(new { message = "Movie not found." });
        }

        var reviews = await _context.Reviews
            .Where(r => r.MovieId == movie.Id)
            .Include(r => r.User) // Eager loading User
            .Select(r => new
            {
                r.Id,
                r.Content,
                r.Rating,
                User = new { r.User.Id, r.User.Username }
            })
            .ToListAsync();

        return Ok(reviews);
    }
}

public class AddReviewRequest
{
    public int TmdbMovieId { get; set; }
    public string Content { get; set; }
    public int Rating { get; set; } // Rating out of 5
}
public class EditReviewRequest
{
    public string Content { get; set; }
    public int Rating { get; set; } // Rating out of 5
}