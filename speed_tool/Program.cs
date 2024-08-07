using System;
using System.IO;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using CommandLine;

class Options
{
    [Option('s', "size", Default = 1, HelpText = "Test size in GiB")]
    public int TestSize { get; set; }

    [Option('d', "drive", Default = "C", HelpText = "Drive letter to test")]
    public string TestDrive { get; set; }
}

class Program
{
    static async Task Main(string[] args)
    {
        await Parser.Default.ParseArguments<Options>(args)
            .WithParsedAsync(RunTests);
    }

    static async Task RunTests(Options opts)
    {
        string testPath = Path.Combine(opts.TestDrive + ":\\\\", "SpeedTest");
        string testFile = Path.Combine(testPath, "speedtest.dat");
        long testSizeBytes = opts.TestSize * 1024L * 1024L * 1024L;

        Directory.CreateDirectory(testPath);

        Console.WriteLine($"Running disk speed test on drive {opts.TestDrive}");
        Console.WriteLine($"Test size: {opts.TestSize} GiB");

        // Sequential, 1MiB, Q8T1
        await RunTest(testFile, testSizeBytes, "Sequential", 1024 * 1024, 8, 1);
        await Task.Delay(5000); // 5 second interval

        // Sequential, 1MiB, Q1T1
        await RunTest(testFile, testSizeBytes, "Sequential", 1024 * 1024, 1, 1);
        await Task.Delay(5000);

        // Random, 4KiB, Q32T1
        await RunTest(testFile, testSizeBytes, "Random", 4 * 1024, 32, 1);
        await Task.Delay(5000);

        // Random, 4KiB, Q1T1
        await RunTest(testFile, testSizeBytes, "Random", 4 * 1024, 1, 1);

        File.Delete(testFile);
    }

    static async Task RunTest(string file, long size, string mode, int blockSize, int queueDepth, int threadCount)
    {
        Console.WriteLine($"\\n{mode} Test (Block: {blockSize / 1024}KiB, Q={queueDepth}, T={threadCount})");

        long writeBytes = await RunOperation(file, size, mode, blockSize, queueDepth, threadCount, isWrite: true);
        double writeMBps = writeBytes / (5.0 * 1024 * 1024);
        Console.WriteLine($"Write: {writeMBps:F2} MB/s");

        await Task.Delay(1000); // Short delay between write and read

        long readBytes = await RunOperation(file, size, mode, blockSize, queueDepth, threadCount, isWrite: false);
        double readMBps = readBytes / (5.0 * 1024 * 1024);
        Console.WriteLine($"Read: {readMBps:F2} MB/s");
    }

    static async Task<long> RunOperation(string file, long size, string mode, int blockSize, int queueDepth, int threadCount, bool isWrite)
    {
        using var fs = new FileStream(file, isWrite ? FileMode.Create : FileMode.Open,
                                      isWrite ? FileAccess.Write : FileAccess.Read,
                                      FileShare.None, blockSize, FileOptions.None);

        var cts = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(5));
        var bytesProcessed = new ConcurrentQueue<long>();

        async Task ProcessData()
        {
            var random = new Random();
            byte[] buffer = new byte[blockSize];
            long position = 0;

            while (!cts.IsCancellationRequested)
            {
                if (mode == "Random")
                    position = random.NextInt64(0, size - blockSize);

                fs.Position = position;

                if (isWrite)
                {
                    random.NextBytes(buffer);
                    await fs.WriteAsync(buffer, 0, blockSize, cts.Token);
                }
                else
                {
                    await fs.ReadAsync(buffer, 0, blockSize, cts.Token);
                }

                bytesProcessed.Enqueue(blockSize);

                if (mode == "Sequential")
                    position += blockSize;
                if (position >= size)
                    position = 0;
            }
        }

        var tasks = Enumerable.Range(0, queueDepth)
                              .Select(_ => ProcessData())
                              .ToArray();

        try
        {
            await Task.WhenAll(tasks);
        }
        catch (OperationCanceledException)
        {
            // Expected when the timer expires
        }

        return bytesProcessed.Sum();
    }
}
