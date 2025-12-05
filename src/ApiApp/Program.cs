using Microsoft.EntityFrameworkCore;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure Azure Key Vault
var keyVaultUri = Environment.GetEnvironmentVariable("KeyVaultUri");
if (!string.IsNullOrEmpty(keyVaultUri))
{
    var credential = new DefaultAzureCredential();
    var keyVaultClient = new SecretClient(new Uri(keyVaultUri), credential);
    
    // Get connection string from Key Vault
    var connectionStringSecret = await keyVaultClient.GetSecretAsync("sql-connection-string");
    builder.Configuration["ConnectionStrings:DefaultConnection"] = connectionStringSecret.Value.Value;
}

// Configure Entity Framework with SQL Database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApiDbContext>(options =>
    options.UseSqlServer(connectionString));

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwagger();
app.UseSwaggerUI();

app.UseAuthorization();

// API endpoints
app.MapGet("/api/customers", async (ApiDbContext dbContext) =>
{
    var customers = await dbContext.Customers.ToListAsync();
    return Results.Ok(customers);
});

app.MapGet("/api/customers/{id}", async (int id, ApiDbContext dbContext) =>
{
    var customer = await dbContext.Customers.FindAsync(id);
    return customer != null ? Results.Ok(customer) : Results.NotFound();
});

app.MapPost("/api/customers", async (Customer customer, ApiDbContext dbContext) =>
{
    dbContext.Customers.Add(customer);
    await dbContext.SaveChangesAsync();
    return Results.Created($"/api/customers/{customer.Id}", customer);
});

app.MapGet("/api/health", () => Results.Ok(new { Status = "API Healthy", Timestamp = DateTime.UtcNow }));

app.MapControllers();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApiDbContext>();
    await context.Database.EnsureCreatedAsync();
}

app.Run();

public class ApiDbContext : DbContext
{
    public ApiDbContext(DbContextOptions<ApiDbContext> options) : base(options) { }
    
    public DbSet<Customer> Customers { get; set; } = null!;
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>().HasData(
            new Customer { Id = 1, Name = "API Customer 1", Email = "api1@example.com" },
            new Customer { Id = 2, Name = "API Customer 2", Email = "api2@example.com" }
        );
    }
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}