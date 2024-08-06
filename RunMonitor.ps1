# Requires -RunAsAdministrator

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Monitor {
    param (
        [string]$command
    )

    if (Test-Admin) {
        while ($true) {
            # Create a directory with the current datetime as its name
            $current_time = Get-Date -Format "yyyyMMdd_HHmmss"
            $newDir = New-Item -ItemType Directory -Path $current_time -Force
            
            # Change the working directory to the newly created folder
            Push-Location $newDir
            
            # Run the command in the newly created folder
            Invoke-Expression $command
            
            # Change back to the parent directory
            Pop-Location
            
            # Wait for 5 minutes, showing a countdown
            for ($i = 300; $i -gt 0; $i--) {
                Write-Host "`rNext run in $i seconds..." -NoNewline
                Start-Sleep -Seconds 1
            }
            Write-Host "`nRunning command again..."
        }
    } else {
        Write-Host "This script requires admin privileges. Please run it as an admin."
        exit
    }
}

# Main execution
& ".\.venv\Scripts\Activate.ps1"

$command = "viewnvme"
Invoke-Monitor -command $command
