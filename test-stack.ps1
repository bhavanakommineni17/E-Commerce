# Automated MERN Stack and Docker Verification Script

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     OmniStore MERN Stack and Docker Verification Suite   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Docker Status Check
Write-Host "`n[1/4] Checking Docker Containers..." -ForegroundColor Yellow
$containers = docker compose ps --format json | ConvertFrom-Json
$expectedServices = @("backend", "frontend", "mongo")

foreach ($svc in $expectedServices) {
    $match = $containers | Where-Object { $_.Service -eq $svc }
    if ($match -and ($match.State -eq "running" -or $match.Status -match "Up")) {
        Write-Host "  ✔ Service '$svc' is RUNNING ($($match.Status))" -ForegroundColor Green
    } else {
        Write-Host "  ✖ Service '$svc' is NOT running as expected!" -ForegroundColor Red
        exit 1
    }
}

# 2. Database and Backend Health
Write-Host "`n[2/4] Testing Backend and MongoDB Connection..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 5
    if ($health.status -eq "UP" -and $health.mongodb -eq "connected") {
        Write-Host "  ✔ Health Endpoint: UP (MongoDB: Connected)" -ForegroundColor Green
    } else {
        Write-Host "  ✖ Backend health degraded: $($health | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✖ Failed to reach http://localhost:5000/health: $_" -ForegroundColor Red
    exit 1
}

# 3. Product Catalog and Nginx Proxy
Write-Host "`n[3/4] Testing Frontend Nginx Reverse Proxy and Catalog..." -ForegroundColor Yellow
try {
    $products = Invoke-RestMethod -Uri "http://localhost:3000/api/products" -Method Get -TimeoutSec 5
    if ($products.Count -ge 6) {
        Write-Host "  ✔ Catalog API via Port 3000: $($products.Count) products retrieved" -ForegroundColor Green
    } else {
        Write-Host "  ✖ Expected at least 6 products, got $($products.Count)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✖ Failed to query products via Nginx: $_" -ForegroundColor Red
    exit 1
}

# 4. End-to-End Order Transaction
Write-Host "`n[4/4] Testing Order Transaction and Database Write..." -ForegroundColor Yellow
try {
    $body = @{
        customer = @{ name = "Automated Stack Verifier"; email = "verify@ecom.local" }
        items = @(@{ name = "Test Headset"; price = 199.99; quantity = 1 })
        totalAmount = 199.99
    } | ConvertTo-Json

    $order = Invoke-RestMethod -Uri "http://localhost:3000/api/orders" -Method Post -ContentType "application/json" -Body $body
    if ($order.orderId -and $order.status -eq "Confirmed") {
        Write-Host "  ✔ Order Created and Persisted! ID: $($order.orderId) (Total: `$$($order.totalAmount))" -ForegroundColor Green
    } else {
        Write-Host "  ✖ Order failed: $($order | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✖ Failed to submit order: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "       ALL VERIFICATION CHECKS PASSED SUCCESSFULLY!       " -ForegroundColor Green
Write-Host "           Project is 100% Ready for Submission           " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
