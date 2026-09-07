import Foundation

/// Reads modern (SMAppService) Login Item / background-task registrations via
/// `sfltool dumpbtm`. Read-only: these registrations live in a system database with
/// no direct file to delete, so we can only surface them for manual review in
/// System Settings > General > Login Items.
///
/// macOS prompts for authorization on this call when launched from an unsigned/ad-hoc
/// GUI app. Selecting an app used to re-run `dumpbtm` on every scan, which meant a fresh
/// prompt per app; the dump is cached for the lifetime of the process so the user is
/// asked at most once per launch.
enum LoginItemsService {
    // Worst case on a race is one redundant `sfltool dumpbtm` call (and its auth
    // prompt), not corrupted state — an actor would be overkill for a String?.
    nonisolated(unsafe) private static var cachedDump: String?
    nonisolated(unsafe) private static var didAttemptDump = false

    private static func dump() -> String? {
        if didAttemptDump { return cachedDump }
        didAttemptDump = true
        guard let sfltoolPath = ProcessRunner.resolveExecutable("sfltool", knownPaths: ["/usr/bin/sfltool"]) else { return nil }
        let result = ProcessRunner.run(sfltoolPath, ["dumpbtm"], timeout: 10)
        guard result.exitCode == 0 else { return nil }
        cachedDump = result.stdout
        return result.stdout
    }

    static func matchingEntries(app: InstalledApp) -> [String] {
        guard let output = dump() else { return [] }
        let blocks = output.components(separatedBy: "\n\n")
        return blocks.filter { block in
            let lower = block.lowercased()
            if lower.contains(app.bundleID.lowercased()) { return true }
            guard app.name.count >= 5 else { return false }
            return lower.contains(app.name.lowercased())
        }
    }
}
