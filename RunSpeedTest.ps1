function Test-DiskSpeed {
    # Prompt user for test parameters
    $testCount = Read-Host "Enter the number of tests to run (default is 5)"
    if ([string]::IsNullOrWhiteSpace($testCount)) { $testCount = 5 } else { $testCount = [int]$testCount }

    $testSize = Read-Host "Enter the test size in GiB (default is 1)"
    if ([string]::IsNullOrWhiteSpace($testSize)) { $testSize = 1 } else { $testSize = [int]$testSize }

    $testDrive = Read-Host "Enter the drive letter to test (default is C)"
    if ([string]::IsNullOrWhiteSpace($testDrive)) { $testDrive = "C" }
    $testPath = "${testDrive}:\SpeedTest"

    # Convert GiB to bytes
    $testSizeBytes = $testSize * 1GB

    # Create test directory if it doesn't exist
    if (-not (Test-Path $testPath)) {
        New-Item -ItemType Directory -Path $testPath | Out-Null
    }

    $testFile = Join-Path $testPath "speedtest.dat"

    function Measure-IOSpeed {
        param (
            [string]$Operation,
            [scriptblock]$ScriptBlock,
            [int]$BlockSize,
            [int]$QueueDepth,
            [int]$ThreadCount
        )

        $results = 1..$testCount | ForEach-Object {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            & $ScriptBlock
            $sw.Stop()
            $speed = $testSizeBytes / $sw.Elapsed.TotalSeconds / 1MB
            [PSCustomObject]@{
                Speed = $speed
            }
        }

        $avgSpeed = ($results.Speed | Measure-Object -Average).Average
        Write-Host "${Operation} (Block: ${BlockSize}, Q=${QueueDepth}, T=${ThreadCount}): $($avgSpeed.ToString("F2")) MB/s"
    }

    function Create-TestFile {
        $fs = [System.IO.File]::OpenWrite($testFile)
        $buffer = New-Object byte[] 1MB
        $random = New-Object Random

        for ($i = 0; $i -lt $testSizeBytes; $i += 1MB) {
            $random.NextBytes($buffer)
            $fs.Write($buffer, 0, $buffer.Length)
        }

        $fs.Close()
    }

    function Perform-SequentialIO {
        param (
            [string]$Operation,
            [int]$QueueDepth,
            [int]$ThreadCount
        )

        $blockSize = 1MB
        $scriptBlock = {
            if ($Operation -eq "Write") {
                $fs = [System.IO.File]::OpenWrite($testFile)
                $buffer = New-Object byte[] $blockSize
                $random = New-Object Random

                for ($i = 0; $i -lt $testSizeBytes; $i += $blockSize) {
                    $random.NextBytes($buffer)
                    $fs.Write($buffer, 0, $buffer.Length)
                }
            } else {
                $fs = [System.IO.File]::OpenRead($testFile)
                $buffer = New-Object byte[] $blockSize

                while ($fs.Position -lt $fs.Length) {
                    $fs.Read($buffer, 0, $buffer.Length) | Out-Null
                }
            }

            $fs.Close()
        }

        Measure-IOSpeed -Operation "Sequential $Operation" -ScriptBlock $scriptBlock -BlockSize $blockSize -QueueDepth $QueueDepth -ThreadCount $ThreadCount
    }

    function Perform-RandomIO {
        param (
            [string]$Operation,
            [int]$QueueDepth,
            [int]$ThreadCount
        )

        $blockSize = 4KB
        $scriptBlock = {
            if ($Operation -eq "Write") {
                $fs = [System.IO.File]::OpenWrite($testFile)
            } else {
                $fs = [System.IO.File]::OpenRead($testFile)
            }
            $buffer = New-Object byte[] $blockSize
            $random = New-Object Random

            for ($i = 0; $i -lt ($testSizeBytes / $blockSize); $i++) {
                $fs.Position = $random.Next(0, [Math]::Max(1, $testSizeBytes - $blockSize))
                if ($Operation -eq "Write") {
                    $random.NextBytes($buffer)
                    $fs.Write($buffer, 0, $buffer.Length)
                } else {
                    $fs.Read($buffer, 0, $buffer.Length) | Out-Null
                }
            }

            $fs.Close()
        }

        Measure-IOSpeed -Operation "Random $Operation" -ScriptBlock $scriptBlock -BlockSize $blockSize -QueueDepth $QueueDepth -ThreadCount $ThreadCount
    }

    # Perform tests
    Write-Host "Starting Disk Speed Test..."
    Write-Host "Test Count: $testCount"
    Write-Host "Test Size: $testSize GiB"
    Write-Host "Test Drive: $testDrive`n"

    # Create initial test file
    Write-Host "Creating test file..."
    Create-TestFile

    # Sequential 1MiB (Q=8, T=1)
    Perform-SequentialIO -Operation "Write" -QueueDepth 8 -ThreadCount 1
    Perform-SequentialIO -Operation "Read" -QueueDepth 8 -ThreadCount 1

    # Sequential 1MiB (Q=1, T=1)
    Perform-SequentialIO -Operation "Write" -QueueDepth 1 -ThreadCount 1
    Perform-SequentialIO -Operation "Read" -QueueDepth 1 -ThreadCount 1

    # Random 4KiB (Q=32, T=1)
    Perform-RandomIO -Operation "Write" -QueueDepth 32 -ThreadCount 1
    Perform-RandomIO -Operation "Read" -QueueDepth 32 -ThreadCount 1

    # Random 4KiB (Q=1, T=1)
    Perform-RandomIO -Operation "Write" -QueueDepth 1 -ThreadCount 1
    Perform-RandomIO -Operation "Read" -QueueDepth 1 -ThreadCount 1

    # Clean up
    Remove-Item $testFile -Force
}

# Run the disk speed test
Test-DiskSpeed