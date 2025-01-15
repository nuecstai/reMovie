namespace removie.Models
{
    public class Review
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int MovieId { get; set; }
        public string Content { get; set; }
        public int Rating { get; set; } // Rating out of 5

        // Navigation properties
        public User User { get; set; }
        public Movie Movie { get; set; }
    }
}
