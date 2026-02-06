# Set the secret key for integration tests
$env:SECRET_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Run unit tests only (no network required)
Write-Host "Running unit tests..." -ForegroundColor Cyan
dotnet test --settings test.runsettings --filter "Category!=Integration"

# Uncomment below to run ALL tests (requires local network running)
# Write-Host "Running all tests including integration..." -ForegroundColor Cyan
# dotnet test --settings test.runsettings
