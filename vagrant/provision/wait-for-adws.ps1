$maxAttempts = 20
$attempt = 0
$ready = $false

while (-not $ready -and $attempt -lt $maxAttempts) {
    $svc = Get-Service -Name ADWS -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
            Get-ADDomain -ErrorAction Stop | Out-Null
            $ready = $true
            Write-Host "ADWS is running and AD DS is responsive."
        }
        catch {
            Write-Host "ADWS service running but AD DS not yet responsive. Retrying..."
        }
    }
    else {
        Write-Host "ADWS not yet running. Retrying..."
    }

    if (-not $ready) {
        Start-Sleep -Seconds 15
        $attempt++
    }
}

if (-not $ready) {
    Write-Error "ADWS did not become ready after $maxAttempts attempts."
    exit 1
}