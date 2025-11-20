# scripts/Create-RDPUser.ps1

try {
    $ErrorActionPreference = "Stop"

    Add-Type -AssemblyName System.Security
    
    # Generate a random password
    $charSet = @{
        Upper   = [char[]](65..90)
        Lower   = [char[]](97..122)
        Number  = [char[]](48..57)
        Special = ([char[]](33..47) + [char[]](58..64) +
                   [char[]](91..96) + [char[]](123..126))
    }
    $rawPassword = @()
    $rawPassword += $charSet.Upper | Get-Random -Count 4
    $rawPassword += $charSet.Lower | Get-Random -Count 4
    $rawPassword += $charSet.Number | Get-Random -Count 4
    $rawPassword += $charSet.Special | Get-Random -Count 4
    $password = -join ($rawPassword | Sort-Object { Get-Random })
    
    # Mask the password in logs
    echo "::add-mask::$password"
    
    # Create the user
    $securePass = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name "RDP" -Password $securePass -AccountNeverExpires
    
    # Add user to relevant groups
    Add-LocalGroupMember -Group "Administrators" -Member "RDP"
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "RDP"
   
    # Set outputs for the workflow
    echo "rdp_user=RDP" >> $env:GITHUB_OUTPUT
    echo "rdp_password=$password" >> $env:GITHUB_OUTPUT
   
    # Verify user was created
    if (-not (Get-LocalUser -Name "RDP")) {
        Write-Error "User creation failed"
        exit 1
    }

    Write-Host "Successfully created and configured RDP user."
}
catch {
    Write-Error "Failed to create RDP user: $_"
    exit 1
}
