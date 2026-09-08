import Foundation

/// Reads modern (SMAppService) Login Item / background-task registrations via
/// `sfltool dumpbtm`. Read-only: these registrations live in a system database with
/// no direct file to delete, so we can only surface them for manual review in
/// System Settings > General > Login Items.
///
/// macOS prompts for authorization on this call when launched from an unsigned/ad-hoc
/// GUI app — that prompt is shown by the OS's Authorization Services around the sfltool
/// binary itself, so Vestige has no way to add a Touch ID option or otherwise suppress
/// it. What Vestige can control is how often it asks: the result is cached in
/// UserDefaults (so it survives app restarts, not just the current process) and
/// refreshed at most once every `cacheValidity` — old enough that most users only see
/// the prompt every so often, fresh enough that a since-installed app's login item
/// still gets picked up eventually.
enum LoginItemsService {
    private static let cacheKey = "LoginItemsService.dumpCache"
    private static let cacheDateKey = "LoginItemsService.dumpCacheDate"
    static let cacheValidity: TimeInterval = 7 * 24 * 60 * 60

    // Worst case on a race is one redundant `sfltool dumpbtm` call (and its auth
    // prompt), not corrupted state — an actor would be overkill for a String?.
    nonisolated(unsafe) private static var inMemoryDump: String?
    nonisolated(unsafe) private static var didAttemptDump = false

    static func isCacheValid(cachedAt: Date, now: Date = Date()) -> Bool {
        now.timeIntervalSince(cachedAt) < cacheValidity
    }

    private static func dump() -> String? {
        if didAttemptDump { return inMemoryDump }
        didAttemptDump = true

        let defaults = UserDefaults.standard
        if let cachedDate = defaults.object(forKey: cacheDateKey) as? Date,
           isCacheValid(cachedAt: cachedDate),
           let cached = defaults.string(forKey: cacheKey) {
            inMemoryDump = cached
            return cached
        }

        guard let sfltoolPath = ProcessRunner.resolveExecutable("sfltool", knownPaths: ["/usr/bin/sfltool"]) else { return nil }
        let result = ProcessRunner.run(sfltoolPath, ["dumpbtm"], timeout: 10)
        guard result.exitCode == 0 else { return nil }

        defaults.set(result.stdout, forKey: cacheKey)
        defaults.set(Date(), forKey: cacheDateKey)
        inMemoryDump = result.stdout
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
