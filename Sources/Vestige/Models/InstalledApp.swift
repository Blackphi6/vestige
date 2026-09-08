import Foundation
import AppKit

enum AppSource: String, Sendable {
    case applications = "Applications"
    case homebrewCask = "Homebrew Cask"
    // A GUI app whose Formula (not Cask) puts its .app bundle straight in the Cellar
    // instead of installing to /Applications — e.g. `brew install thock` (Formula) vs.
    // `brew install --cask thock`. Easy to miss since it never shows up in a
    // /Applications listing or a Cask-only Homebrew scan.
    case homebrewFormula = "Homebrew Formula"
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
    let homebrewFormulaName: String?

    init(
        id: String,
        name: String,
        bundleID: String,
        version: String,
        appPath: URL,
        source: AppSource,
        homebrewCaskToken: String? = nil,
        homebrewZapTrashPatterns: [String] = [],
        homebrewFormulaName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.version = version
        self.appPath = appPath
        self.source = source
        self.homebrewCaskToken = homebrewCaskToken
        self.homebrewZapTrashPatterns = homebrewZapTrashPatterns
        self.homebrewFormulaName = homebrewFormulaName
    }

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
