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
& ".\required_apps\python-3.9.0-amd64.exe"

& ".\required_apps\fio-3.37-x64.msi"

& "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python39\python.exe" -m venv .venv

& ".\.venv\Scripts\Activate.ps1"

pip install --no-index --find-links=./packages_src nvmetools

if (-not (Test-Path -Path "C:\Users\$env:USERNAME\Documents\nvmetools\suites")) {
    New-Item -ItemType Directory -Path "C:\Users\$env:USERNAME\Documents\nvmetools\suites"
}
Get-ChildItem -Path ".\suites" | Move-Item -Destination "C:\Users\$env:USERNAME\Documents\nvmetools\suites"

& ".\RunMonitor.ps1"

# To keep the window open (if you want to see the output), uncomment the next line
Read-Host -Prompt "Press Enter to exit"
