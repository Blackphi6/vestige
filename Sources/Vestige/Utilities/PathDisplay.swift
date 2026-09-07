import Foundation

/// Renders paths with the user's home directory collapsed to `~`, matching Terminal/
/// Finder convention. Keeps the real account name out of on-screen text, screenshots,
/// and demo recordings.
enum PathDisplay {
    static func string(for path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    static func string(for url: URL) -> String {
        string(for: url.path)
    }
}
