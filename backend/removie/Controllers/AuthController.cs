using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using removie.Data;
using removie.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly MovieReviewContext _context;
    private readonly IConfiguration _configuration;

    public AuthController(MovieReviewContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    [HttpPost("signup")]
    public async Task<IActionResult> SignUp([FromBody] SignUpRequest request)
    {
        if (await _context.Users.AnyAsync(u => u.Username == request.Username || u.Email == request.Email))
        {
            return BadRequest(new { message = "Username or email already exists." });
        }

        var passwordHash = request.Password;

        var user = new User
        {
            Username = request.Username,
            Email = request.Email,
            PasswordHash = passwordHash
        };

        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();

        return Ok(new { message = "User created successfully!" });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var user = await _context.Users.SingleOrDefaultAsync(u => u.Username == request.Username);
            if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Invalid username or password." });
            }

            var token = GenerateJwtToken(user);
            return Ok(new { message = "Login successful!", token });
        }
        catch (Exception ex)
        {
            // Log the exception details for debugging
            Console.Error.WriteLine("Error during login: " + ex.Message);

            // Return a JSON response with a generic error message
            return StatusCode(500, new { message = "An error occurred on the server. Please try again later." });
        }
    }

    [Authorize]
    [HttpPut("edit-profile")]
    public async Task<IActionResult> EditProfile([FromBody] EditProfileRequest request)
    {
        // Retrieve the authenticated user's username from the JWT token
        var username = User.FindFirstValue(ClaimTypes.NameIdentifier);

        // Find the user in the database by username
        var user = await _context.Users.SingleOrDefaultAsync(u => u.Username == username);
        if (user == null)
        {
            return Unauthorized(new { message = "User not found." });
        }

        // Update username if provided
        if (!string.IsNullOrEmpty(request.NewUsername))
        {
            // Check if the new username is already taken
            if (await _context.Users.AnyAsync(u => u.Username == request.NewUsername && u.Username != username))
            {
                return BadRequest(new { message = "Username already exists." });
            }

            user.Username = request.NewUsername;
        }

        // Update password if provided
        if (!string.IsNullOrEmpty(request.NewPassword))
        {
            user.PasswordHash = request.NewPassword;
        }

        // Save changes to the database
        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        // Generate a new token with updated username
        var newToken = GenerateJwtToken(user);

        return Ok(new { message = "Profile updated successfully!", token = newToken });
    }

    [Authorize]
    [HttpDelete("delete-account")]
    public async Task<IActionResult> DeleteAccount([FromBody] DeleteAccountRequest request)
    {
        try
        {
            // Retrieve the authenticated user's username from the JWT token
            var username = User.FindFirstValue(ClaimTypes.NameIdentifier);

            // Find the user in the database by username
            var user = await _context.Users
                .Include(u => u.FavoriteMovies)
                .Include(u => u.WatchlistMovies)
                .SingleOrDefaultAsync(u => u.Username == username);

            if (user == null)
            {
                return Unauthorized(new { message = "User not found." });
            }

            // Verify the provided password
            if (!VerifyPassword(request.Password, user.PasswordHash))
            {
                return BadRequest(new { message = "Invalid password." });
            }

            // Remove the user's account
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Account deleted successfully!" });
        }
        catch (Exception ex)
        {
            // Log error for debugging
            Console.Error.WriteLine("Error deleting account: " + ex.Message);

            return StatusCode(500, new { message = "An error occurred while deleting the account. Please try again later." });
        }
    }


    private bool VerifyPassword(string password, string storedHash)
    {
        using var hmac = new HMACSHA512();
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
        var computedHash = Convert.ToBase64String(hash);
        return password == storedHash;
    }

    private string HashPassword(string password)
    {
        using var hmac = new HMACSHA512();
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
        return Convert.ToBase64String(hash);
    }

    private string GenerateJwtToken(User user)
    {
        try
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.IsAdmin ? "Admin" : "User") // Add role claim
        };

            var token = new JwtSecurityToken(
                issuer: jwtSettings["Issuer"],
                audience: jwtSettings["Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["ExpirationInMinutes"])),
                signingCredentials: creds
            );

            Console.WriteLine("Token generated successfully.");
            return new JwtSecurityTokenHandler().WriteToken(token);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("Error generating token: " + ex.Message);
            throw;
        }
    }


}


public class SignUpRequest
{
    public string Username { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
}
public class LoginRequest
{
    public string Username { get; set; }
    public string Password { get; set; }
}

public class EditProfileRequest
{
    public string NewUsername { get; set; }
    public string NewPassword { get; set; }
}

public class DeleteAccountRequest
{
    public string Password { get; set; }
}
