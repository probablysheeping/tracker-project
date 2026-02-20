namespace PTVApp.Models
{
    public class ApiUser
    {
        public required string Username { get; set; }
        public required string ApiKey { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;
    }

    public class ApiAuthRequest
    {
        public required string Username { get; set; }
        public required string ApiKey { get; set; }
    }
}
