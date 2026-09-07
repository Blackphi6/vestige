import Foundation
import AppKit

enum AppSource: String, Sendable {
    case applications = "Applications"
    case homebrewCask = "Homebrew Cask"
}

struct InstalledApp: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let bundleID: String
    let version: String
    let appPath: URL
    let source: AppSource
    let homebrewCaskToken: String?
    let homebrewZapTrashPatterns: [String]

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: appPath.path)
    }
}
