# Test Register and Forgot Password Flow
$email = "kai7538617@gmail.com"
$password = "123456"
$fullName = "Test User"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "STEP 1: Register Account" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$registerBody = @{
    email = $email
    password = $password
    full_name = $fullName
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/register" `
        -Method POST `
        -Body $registerBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "Register Success!" -ForegroundColor Green
    $registerResponse | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "Account already exists, continuing to forgot password..." -ForegroundColor Yellow
    } else {
        Write-Host "Register Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "STEP 2: Forgot Password" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

Start-Sleep -Seconds 1

$forgotBody = @{
    email = $email
} | ConvertTo-Json

try {
    $forgotResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/forgot-password" `
        -Method POST `
        -Body $forgotBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "Forgot Password Response:" -ForegroundColor Green
    $forgotResponse | ConvertTo-Json -Depth 5 | Write-Host
    
    if ($forgotResponse.temporary_password) {
        Write-Host ""
        Write-Host "==================================" -ForegroundColor Magenta
        Write-Host "TEMPORARY PASSWORD FOUND!" -ForegroundColor Magenta
        Write-Host "==================================" -ForegroundColor Magenta
        Write-Host $forgotResponse.temporary_password -ForegroundColor Yellow
        Write-Host "==================================" -ForegroundColor Magenta
    } else {
        Write-Host ""
        Write-Host "No temporary_password in response" -ForegroundColor Yellow
        Write-Host "Check server console for email log" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Forgot Password Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Check server console for email!" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
