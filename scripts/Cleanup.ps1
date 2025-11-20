# scripts/Cleanup.ps1

$ErrorActionPreference = "Continue"
$backupFile = "$env:TEMP\rdp_backup.json"

Write-Host "--- Starting Cleanup ---"

# --- Restore RDP Settings ---
if (Test-Path $backupFile) {
    try {
        Write-Host "Restoring original RDP settings from backup..."
        $backup = Get-Content -Path $backupFile | ConvertFrom-Json
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value $backup.fDenyTSConnections -Force
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value $backup.UserAuthentication -Force
        Write-Host "RDP settings successfully restored."
        Remove-Item $backupFile -Force
    } catch {
        Write-Warning "Failed to restore RDP settings: $_"
    }
} else {
    Write-Warning "RDP backup file not found. Skipping restore."
}

# --- Disconnect Tailscale ---
Write-Host "Disconnecting Tailscale..."
& "$env:ProgramFiles\Tailscale\tailscale.exe" logout

# --- Remove Firewall Rule ---
Write-Host "Removing firewall rule..."
Remove-NetFirewallRule -DisplayName "RDP-Tailscale"

# --- Remove RDP User ---
Write-Host "Removing RDP user..."
Remove-LocalUser -Name "RDP"

Write-Host "--- Cleanup Complete ---"
