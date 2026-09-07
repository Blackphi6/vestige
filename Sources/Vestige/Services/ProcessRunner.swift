import Foundation

/// Written from exactly one background queue and read only after that queue's
/// DispatchGroup has signaled completion, so the unsynchronized access is safe in
/// practice even though the compiler can't see that.
private final class DataBox: @unchecked Sendable {
    var value = Data()
}

enum ProcessRunner {
    struct Result {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    /// Runs an executable at an absolute path and captures its output.
    /// Never routes through a shell, so arguments are not subject to shell interpretation.
    @discardableResult
    static func run(_ executablePath: String, _ arguments: [String], timeout: TimeInterval = 30) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        // A GUI app's process doesn't inherit the user's shell PATH (no /opt/homebrew/bin),
        // and Homebrew's own background auto-update check can otherwise add real latency.
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        environment["HOMEBREW_NO_ANALYTICS"] = "1"
        process.environment = environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            return Result(exitCode: -1, stdout: "", stderr: "Failed to launch \(executablePath): \(error.localizedDescription)")
        }

        // Read both pipes concurrently with waiting for exit. A pipe's kernel buffer is
        // only 64KB; a child that writes more (e.g. `brew info --json` on a large
        // Caskroom) blocks on write until we drain it, so reading only after
        // waitUntilExit() deadlocks against a child that can never finish writing.
        let stdoutBox = DataBox()
        let stderrBox = DataBox()
        let readQueue = DispatchQueue(label: "ProcessRunner.read", attributes: .concurrent)
        let readGroup = DispatchGroup()

        readGroup.enter()
        readQueue.async {
            stdoutBox.value = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }
        readGroup.enter()
        readQueue.async {
            stderrBox.value = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }

        // `terminationStatus` traps if read before the process has actually exited, so wait
        // for it explicitly (with a timeout) rather than polling `isRunning`.
        let exitGroup = DispatchGroup()
        exitGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            exitGroup.leave()
        }
        if exitGroup.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            exitGroup.wait()
        }
        readGroup.wait()

        return Result(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutBox.value, encoding: .utf8) ?? "",
            stderr: String(data: stderrBox.value, encoding: .utf8) ?? ""
        )
    }

    /// Resolves an executable's absolute path. Checks `knownPaths` first, since a GUI app's
    /// process does not inherit the user's shell PATH (e.g. Homebrew on Apple Silicon lives
    /// at /opt/homebrew/bin, which a login shell adds but a GUI launch never sees), then
    /// falls back to `/usr/bin/which` for anything on the default system PATH.
    static func resolveExecutable(_ name: String, knownPaths: [String] = []) -> String? {
        for path in knownPaths where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        let result = run("/usr/bin/which", [name])
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return (result.exitCode == 0 && !path.isEmpty) ? path : nil
    }
}
