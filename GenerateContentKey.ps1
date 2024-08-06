# Define the output file path
$outputFilePath = ".\Result_GenerateContentKey.txt"

# Create or clear the output file
if (Test-Path $outputFilePath) {
    Clear-Content $outputFilePath
} else {
    New-Item -Path $outputFilePath -ItemType File
}

# Function to safely get file content
function Get-FileContentSafely {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $content = Get-Content -Path $Path -ErrorAction Stop
    } catch {
        $content = "Error reading file content"
    }
    return $content
}

# Prompt the user to enter the path
$userPath = Read-Host "Please enter the path to scan for files"

# Get all files from the user-specified path
$files = Get-ChildItem -Path $userPath -Recurse -File -ErrorAction SilentlyContinue

# Iterate over each file
foreach ($file in $files) {
    # Get the file hash
    $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA1 -ErrorAction SilentlyContinue
    if ($fileHash) {
        $hashString = $fileHash.Hash
    } else {
        $hashString = "Error calculating hash"
    }

    # Get the file content
    $content = Get-FileContentSafely -Path $file.FullName

    # Write the details to the output file
    Add-Content -Path $outputFilePath -Value "$($file.FullName) --- $hashString"
    Add-Content -Path $outputFilePath -Value "$($file.FullName) ___ $content"
    Add-Content -Path $outputFilePath -Value "" # Add an empty line for readability
}

# Output completion message
Write-Host "File details have been written to $outputFilePath"
