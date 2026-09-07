import Foundation

/// Reads installed Homebrew Cask metadata via a single `brew info --json=v2 --installed`
/// call. (Reading the Caskroom's cached `.metadata/**/Casks/<token>.json` directly was
/// tried first but that file is sometimes an empty `{}` depending on brew/cask version,
/// so it can't be relied on.)
enum HomebrewService {
    /// Apple Silicon and Intel default install locations — a GUI app's process doesn't
    /// see the user's shell PATH, so `brew` must be located explicitly.
    private static let knownBrewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    struct CaskInfo {
        let token: String
        let installedAppNames: [String]
        /// Paths from the cask's own `zap` stanza (may contain `~` and glob patterns) —
        /// the cask author's own list of what a full uninstall should remove.
        let zapTrashPatterns: [String]
    }

    static func installedCasks() -> [CaskInfo] {
        guard let brewPath = ProcessRunner.resolveExecutable("brew", knownPaths: knownBrewPaths) else { return [] }
        let result = ProcessRunner.run(brewPath, ["info", "--cask", "--json=v2", "--installed"], timeout: 30)
        guard result.exitCode == 0,
              let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let casks = json["casks"] as? [[String: Any]]
        else { return [] }

        return casks.compactMap { cask in
            guard let token = cask["token"] as? String,
                  let artifacts = cask["artifacts"] as? [[String: Any]]
            else { return nil }

            let appNames = artifacts.compactMap { $0["app"] as? [String] }.flatMap { $0 }
            guard !appNames.isEmpty else { return nil }

            let zapTrash = artifacts
                .compactMap { $0["zap"] as? [[String: Any]] }
                .flatMap { $0 }
                .compactMap { $0["trash"] }
                .flatMap { trashValue -> [String] in
                    if let single = trashValue as? String { return [single] }
                    if let multiple = trashValue as? [String] { return multiple }
                    return []
                }

            return CaskInfo(token: token, installedAppNames: appNames, zapTrashPatterns: zapTrash)
        }
    }

    /// Runs `brew uninstall --zap --force --cask <token>` via the resolved `brew` binary.
    static func uninstallCask(token: String) -> ProcessRunner.Result? {
        guard let brewPath = ProcessRunner.resolveExecutable("brew", knownPaths: knownBrewPaths) else { return nil }
        return ProcessRunner.run(brewPath, ["uninstall", "--zap", "--force", "--cask", token], timeout: 60)
    }
}
