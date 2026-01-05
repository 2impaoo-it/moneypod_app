# Test Forgot Password API
$email = "kai753867@gmail.com"

Write-Host "Testing Forgot Password API..." -ForegroundColor Cyan
Write-Host "Email: $email" -ForegroundColor Yellow
Write-Host ""

$body = @{
    email = $email
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/forgot-password" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5 | Write-Host
    
    if ($response.temporary_password) {
        Write-Host ""
        Write-Host "TEMPORARY PASSWORD:" -ForegroundColor Magenta
        Write-Host "------------------------------------" -ForegroundColor Magenta
        Write-Host $response.temporary_password -ForegroundColor Yellow
        Write-Host "------------------------------------" -ForegroundColor Magenta
    } else {
        Write-Host ""
        Write-Host "WARNING: No temporary_password in response!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Check server console for email log!" -ForegroundColor Cyan
