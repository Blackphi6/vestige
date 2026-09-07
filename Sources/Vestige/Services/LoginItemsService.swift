import Foundation

/// Reads modern (SMAppService) Login Item / background-task registrations via
/// `sfltool dumpbtm`. Read-only: these registrations live in a system database with
/// no direct file to delete, so we can only surface them for manual review in
/// System Settings > General > Login Items.
enum LoginItemsService {
    static func matchingEntries(app: InstalledApp) -> [String] {
        guard let sfltoolPath = ProcessRunner.resolveExecutable("sfltool", knownPaths: ["/usr/bin/sfltool"]) else { return [] }
        let result = ProcessRunner.run(sfltoolPath, ["dumpbtm"], timeout: 10)
        guard result.exitCode == 0 else { return [] }

        let blocks = result.stdout.components(separatedBy: "\n\n")
        return blocks.filter { block in
            let lower = block.lowercased()
            if lower.contains(app.bundleID.lowercased()) { return true }
            guard app.name.count >= 5 else { return false }
            return lower.contains(app.name.lowercased())
        }
    }
}
