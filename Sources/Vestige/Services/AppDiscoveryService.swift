import Foundation

enum AppDiscoveryService {
    static let searchDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
    ]

    static func discoverInstalledApps() -> [InstalledApp] {
        let fm = FileManager.default

        // appFileName ("Thock.app") -> cask info
        var caskByAppName: [String: HomebrewService.CaskInfo] = [:]
        for cask in HomebrewService.installedCasks() {
            for appName in cask.installedAppNames {
                caskByAppName[appName] = cask
            }
        }

        var apps: [InstalledApp] = []
        for directory in searchDirectories {
            guard let entries = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { continue }
            for entry in entries where entry.pathExtension == "app" {
                guard let info = BundleInfoReader.read(appPath: entry) else { continue }
                let appFileName = entry.lastPathComponent
                let cask = caskByAppName[appFileName]
                apps.append(InstalledApp(
                    id: info.bundleID,
                    name: entry.deletingPathExtension().lastPathComponent,
                    bundleID: info.bundleID,
                    version: info.version,
                    appPath: entry,
                    source: cask != nil ? .homebrewCask : .applications,
                    homebrewCaskToken: cask?.token,
                    homebrewZapTrashPatterns: cask?.zapTrashPatterns ?? []
                ))
            }
        }

        // Formula-installed GUI apps live in the Cellar, never in /Applications, so they'd
        // otherwise go completely unnoticed (this is how the Thock case slipped through:
        // its Cask was cleaned up, but a separately-installed Formula copy kept running).
        var seenBundleIDs = Set(apps.map(\.bundleID))
        for formulaApp in HomebrewService.installedFormulaApps() {
            guard let info = BundleInfoReader.read(appPath: formulaApp.appPath),
                  !seenBundleIDs.contains(info.bundleID)
            else { continue }
            seenBundleIDs.insert(info.bundleID)
            apps.append(InstalledApp(
                id: info.bundleID,
                name: formulaApp.appPath.deletingPathExtension().lastPathComponent,
                bundleID: info.bundleID,
                version: info.version,
                appPath: formulaApp.appPath,
                source: .homebrewFormula,
                homebrewFormulaName: formulaApp.formulaName
            ))
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
