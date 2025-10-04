param(
    [string]$DatabaseUrl = "mysql+pymysql://root:@localhost:3308/wedding_db",
    [string]$JwtSecret = "super-secret-key",
    [string]$Hosts = "0.0.0.0",
    [int]$Port = 8000
)

Write-Host "Setting environment variables..."
$env:DATABASE_URL = $DatabaseUrl
$env:JWT_SECRET = $JwtSecret
$env:HOST = $Hosts
$env:PORT = $Port.ToString()

Write-Host "Starting uvicorn server..."

uvicorn main:app --host $Hosts --port $Port --reload