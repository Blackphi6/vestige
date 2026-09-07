import Foundation

/// Finds LaunchAgent/LaunchDaemon plists that reference a given app, by filename
/// or by their Label/Program/ProgramArguments content.
enum LaunchItemScanner {
    static func scan(directory: URL, app: InstalledApp) -> [URL] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        return entries.filter { entry in
            guard entry.pathExtension == "plist" else { return false }
            return matches(fileName: entry.lastPathComponent, app: app) || matchesContent(at: entry, app: app)
        }
    }

    static func matches(fileName: String, app: InstalledApp) -> Bool {
        let lower = fileName.lowercased()
        if lower.contains(app.bundleID.lowercased()) { return true }
        // Short app names (e.g. "Mail") are too generic to trust for a filename match.
        guard app.name.count >= 5 else { return false }
        return lower.contains(app.name.lowercased())
    }

    private static func matchesContent(at url: URL, app: InstalledApp) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return false }

        let label = (plist["Label"] as? String)?.lowercased() ?? ""
        let program = (plist["Program"] as? String)?.lowercased() ?? ""
        let args = (plist["ProgramArguments"] as? [String])?.joined(separator: " ").lowercased() ?? ""
        let haystack = "\(label) \(program) \(args)"

        if haystack.contains(app.bundleID.lowercased()) { return true }
        guard app.name.count >= 5 else { return false }
        return haystack.contains(app.name.lowercased())
    }
}
