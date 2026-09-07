import Foundation

enum ResidueScanner {
    static func scan(for app: InstalledApp) -> [ResidueItem] {
        let fm = FileManager.default
        let library = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        var items: [ResidueItem] = []
        var seenPaths = Set<String>()

        func addIfExists(_ category: ScanCategory, _ path: URL) {
            guard fm.fileExists(atPath: path.path), !seenPaths.contains(path.path) else { return }
            seenPaths.insert(path.path)
            items.append(ResidueItem(
                category: category,
                title: path.lastPathComponent,
                detail: PathDisplay.string(for: path),
                sizeBytes: DirectorySizeCalculator.size(at: path),
                action: .deleteFile(path)
            ))
        }

        // The app bundle itself — previously omitted, so a multi-hundred-MB app showed up
        // nowhere in the scan and its size never factored into the total. Homebrew Casks
        // skip this: `brew uninstall --zap` already removes the bundle, so its size is
        // attached to the Homebrew Cask entry below instead of listing it twice.
        if app.homebrewCaskToken == nil {
            addIfExists(.appBundle, app.appPath)
        }

        addIfExists(.applicationSupport, library.appendingPathComponent("Application Support/\(app.name)"))
        if !app.bundleID.isEmpty {
            addIfExists(.applicationSupport, library.appendingPathComponent("Application Support/\(app.bundleID)"))
            addIfExists(.preferences, library.appendingPathComponent("Preferences/\(app.bundleID).plist"))
            addIfExists(.caches, library.appendingPathComponent("Caches/\(app.bundleID)"))
            addIfExists(.httpStorages, library.appendingPathComponent("HTTPStorages/\(app.bundleID)"))
            addIfExists(.containers, library.appendingPathComponent("Containers/\(app.bundleID)"))
            addIfExists(.savedState, library.appendingPathComponent("Saved Application State/\(app.bundleID).savedState"))
            addIfExists(.webKit, library.appendingPathComponent("WebKit/\(app.bundleID)"))
        }
        addIfExists(.logs, library.appendingPathComponent("Logs/\(app.name)"))

        let groupContainers = library.appendingPathComponent("Group Containers")
        if let entries = try? fm.contentsOfDirectory(at: groupContainers, includingPropertiesForKeys: nil) {
            let suffix = groupContainerSuffix(bundleID: app.bundleID)
            for entry in entries where !suffix.isEmpty && entry.lastPathComponent.localizedCaseInsensitiveContains(suffix) {
                addIfExists(.containers, entry)
            }
        }

        for url in LaunchItemScanner.scan(directory: library.appendingPathComponent("LaunchAgents"), app: app) {
            addIfExists(.launchAgents, url)
        }
        for systemDir in ["/Library/LaunchAgents", "/Library/LaunchDaemons"] {
            for url in LaunchItemScanner.scan(directory: URL(fileURLWithPath: systemDir), app: app) {
                guard !seenPaths.contains(url.path) else { continue }
                seenPaths.insert(url.path)
                items.append(ResidueItem(
                    category: .systemLaunchItems,
                    title: url.lastPathComponent,
                    detail: PathDisplay.string(for: url),
                    sizeBytes: nil,
                    action: .manualReviewOnly(url)
                ))
            }
        }

        // Homebrew Cask authors define their own accurate cleanup list in the `zap`
        // stanza — resolve those patterns in addition to our own heuristic scan above.
        for pattern in app.homebrewZapTrashPatterns {
            for path in GlobResolver.resolve(pattern) {
                addIfExists(category(forZapPath: path), URL(fileURLWithPath: path))
            }
        }

        for entry in LoginItemsService.matchingEntries(app: app) {
            let identifierLine = entry
                .split(separator: "\n")
                .first { $0.contains("Identifier") || $0.contains("URL") }
                .map(String.init) ?? entry.prefix(80).description
            items.append(ResidueItem(
                category: .systemLaunchItems,
                title: "Background Item",
                detail: identifierLine.trimmingCharacters(in: .whitespaces),
                sizeBytes: nil,
                action: .informational
            ))
        }

        if let token = app.homebrewCaskToken {
            items.append(ResidueItem(
                category: .homebrewCask,
                title: "Homebrew Cask: \(token)",
                detail: "brew uninstall --zap --force --cask \(token)",
                sizeBytes: DirectorySizeCalculator.size(at: app.appPath),
                action: .uninstallHomebrewCask(token: token)
            ))
        }

        for service in TCCService.commonServices {
            items.append(ResidueItem(
                category: .tccPermissions,
                title: "\(service) permission",
                detail: "tccutil reset \(service) \(app.bundleID)",
                sizeBytes: nil,
                action: .resetTCCService(service: service)
            ))
        }

        if !app.bundleID.isEmpty {
            for path in MDFindService.searchByBundleID(app.bundleID) {
                guard path.hasPrefix(library.path), !seenPaths.contains(path) else { continue }
                let url = URL(fileURLWithPath: path)
                guard url != app.appPath else { continue }
                addIfExists(.other, url)
            }
        }

        return items
    }

    /// Group Containers are typically named "<TeamID>.<bundle-id-suffix>" — use the
    /// last dot-separated bundle-id component as a loose match key.
    static func groupContainerSuffix(bundleID: String) -> String {
        bundleID.split(separator: ".").last.map(String.init) ?? ""
    }

    /// Best-guess category for a path resolved from a cask's `zap` stanza, so it groups
    /// alongside the equivalent heuristically-found items instead of always landing in "Other".
    static func category(forZapPath path: String) -> ScanCategory {
        if path.contains("/Caches/") { return .caches }
        if path.contains("/Preferences/") { return .preferences }
        if path.contains("/Application Support/") { return .applicationSupport }
        if path.contains("/Containers/") || path.contains("/Group Containers/") { return .containers }
        if path.contains("/HTTPStorages/") { return .httpStorages }
        if path.contains("/Saved Application State/") { return .savedState }
        if path.contains("/WebKit/") { return .webKit }
        if path.contains("/Logs/") { return .logs }
        return .other
    }
}
