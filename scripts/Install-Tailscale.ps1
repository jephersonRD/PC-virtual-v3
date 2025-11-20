# scripts/Install-Tailscale.ps1

param (
    [string]$tsUrl
)

$ErrorActionPreference = "Stop"
$installerPath = "$env:TEMP\tailscale.msi"
$maxRetries = 3
$delay = 5 # seconds

for ($i=1; $i -le $maxRetries; $i++) {
    try {
        Write-Host "Attempting to download Tailscale (Attempt $i/$maxRetries)..."
        Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath
        
        Write-Host "Installing Tailscale..."
        Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
        
        Write-Host "Tailscale installed successfully."
        Remove-Item $installerPath -Force
        
        # Verify installation
        $tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
        if (-not (Test-Path $tsExe)) {
            throw "Tailscale executable not found after installation."
        }
        
        Write-Host "Tailscale installation verified."
        exit 0 # Exit with success code
    }
    catch {
        Write-Warning "Failed to install Tailscale on attempt $i: $_"
        if ($i -eq $maxRetries) {
            Write-Error "All attempts to install Tailscale have failed."
            exit 1
        }
        Start-Sleep -Seconds $delay
        $delay *= 2 # Exponential backoff
    }
}
