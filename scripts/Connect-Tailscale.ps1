# scripts/Connect-Tailscale.ps1

param (
    [string]$tailscaleAuthKey,
    [string]$githubRunId
)

$ErrorActionPreference = "Stop"
try {
    # Bring up Tailscale with the provided auth key and set a unique hostname
    $tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
    & $tsExe up --authkey=$tailscaleAuthKey --hostname=gh-runner-$githubRunId
   
    # Wait for Tailscale to assign an IP with exponential backoff
    $tsIP = $null
    $maxRetries = 5
    $delay = 3 # seconds
    for ($i=1; $i -le $maxRetries; $i++) {
        $tsIP = & $tsExe ip -4
        if ($tsIP) {
            Write-Host "Tailscale IP assigned: $tsIP"
            break
        }
        Write-Host "Waiting for Tailscale IP (Attempt $i/$maxRetries)..."
        Start-Sleep -Seconds $delay
        $delay *= 2
    }
   
    if (-not $tsIP) {
        Write-Error "Tailscale IP not assigned after $maxRetries attempts. Exiting."
        exit 1
    }
    
    echo "ts_ip=$tsIP" >> $env:GITHUB_OUTPUT
}
catch {
    Write-Error "Failed to establish Tailscale connection: $_ "
    exit 1
}
