param(
    [string]$BaseUrl = "http://localhost:8080"
)

$endpoints = @(
    "/actuator/health",
    "/actuator/liveness",
    "/actuator/readiness"
)

foreach ($endpoint in $endpoints) {
    $url = "$BaseUrl$endpoint"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ "Accept" = "application/json" }
        $status = $response.status
        Write-Host "[OK] $url -> $status"
    } catch {
        Write-Error "[FAIL] $url -> $($_.Exception.Message)"
        exit 1
    }
}
