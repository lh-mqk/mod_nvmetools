# Requires -RunAsAdministrator

# Check for permissions
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Attempt to elevate privileges if not already running as admin
if (-not (Test-Admin)) {
    Write-Host "Requesting administrative privileges..."
    $currentScript = $MyInvocation.MyCommand.Definition
    Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-File `"$currentScript`""
    exit
}

# Your commands here
& ".\.venv\Scripts\Activate.ps1"

testnvme selftest --nvme 0 --volume C:

# To keep the window open (if you want to see the output), uncomment the next line
# Read-Host -Prompt "Press Enter to exit"
