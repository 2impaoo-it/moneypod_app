# Test SMTP Email Service - PowerShell Script

Write-Host "🧪 Testing SMTP Email Service..." -ForegroundColor Cyan
Write-Host ""

# Check if server is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/ping" -Method GET -ErrorAction Stop
    Write-Host "✅ Server is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Server is not running!" -ForegroundColor Red
    Write-Host "Please start server first: go run cmd/server/main.go" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Get test email
$testEmail = Read-Host "Enter test email address"

if ([string]::IsNullOrWhiteSpace($testEmail)) {
    Write-Host "❌ Email cannot be empty" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Sending forgot password request to: $testEmail" -ForegroundColor Yellow
Write-Host ""

# Prepare request body
$body = @{
    email = $testEmail
} | ConvertTo-Json

# Call API
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/forgot-password" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -ErrorAction Stop
    
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Email sent successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Check your email inbox: $testEmail"
    Write-Host "2. Look for email from 'MoneyPod App'"
    Write-Host "3. If you don't see it, check spam folder"
    Write-Host "4. If SMTP is not configured, check server console logs for password"
    
} catch {
    Write-Host "❌ Failed to send email" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check server logs for details" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
