@echo off
REM Set the secret key for integration tests
set SECRET_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

REM Run the tests (excluding integration tests that need a running network)
"C:\Program Files\dotnet\dotnet.exe" test --settings test.runsettings --filter "Category!=Integration"

REM To run ALL tests including integration tests (requires local network running):
REM "C:\Program Files\dotnet\dotnet.exe" test --settings test.runsettings
