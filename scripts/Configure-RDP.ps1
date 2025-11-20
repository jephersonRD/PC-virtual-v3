# scripts/Configure-RDP.ps1

$ErrorActionPreference = "Stop"
$backupFile = "$env:TEMP\rdp_backup.json"

try {
    # --- Backup original RDP settings ---
    $originalSettings = @{
        fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections").fDenyTSConnections
        UserAuthentication = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication").UserAuthentication
    }
    $originalSettings | ConvertTo-Json | Out-File -FilePath $backupFile
    Write-Host "Original RDP settings backed up to $backupFile"

    # --- Configure new RDP settings ---
    # Enable Remote Desktop and enforce NLA
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                       -Name "fDenyTSConnections" -Value 0 -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                       -Name "UserAuthentication" -Value 1 -Force
    
    # --- Configure Firewall ---
    # Get Tailscale interface
    $tsInterface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "Tailscale*" }
    if (-not $tsInterface) {
        Write-Error "Tailscale network adapter not found."
        exit 1
    }

    # Create a firewall rule scoped to the Tailscale interface
    Remove-NetFirewallRule -DisplayName "RDP-Tailscale" -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "RDP-Tailscale" -Direction Inbound -Action Allow `
      -Protocol TCP -LocalPort 3389 -InterfaceAlias $tsInterface.Name
    Write-Host "Firewall rule 'RDP-Tailscale' created for interface $($tsInterface.Name)."

    # Restart the Remote Desktop service to apply changes
    Restart-Service -Name TermService -Force
    Write-Host "RDP service restarted."
}
catch {
    Write-Error "Failed to configure RDP or firewall: $_ "
    # Attempt to restore from backup on failure
    if (Test-Path $backupFile) {
        Write-Warning "Attempting to restore RDP settings from backup..."
        $backup = Get-Content -Path $backupFile | ConvertFrom-Json
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value $backup.fDenyTSConnections -Force
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value $backup.UserAuthentication -Force
        Write-Host "RDP settings restored."
    }
    exit 1
}
