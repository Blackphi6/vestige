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

    /// `brew uninstall` runs every currently-loaded Cask's deprecated-API checks as a side
    /// effect, so its stderr often mixes in warnings from Casks that have nothing to do
    /// with the one being removed (e.g. some unrelated tap's `postflight` deprecation
    /// notice). Strip those out and translate the one error that matters in practice —
    /// Homebrew's own file-removal permission failure — into Vestige's own guidance,
    /// since `brew`'s process inherits Vestige's Full Disk Access state, not the
    /// terminal's.
    static func cleanedErrorMessage(from result: ProcessRunner.Result?) -> String {
        guard let result else { return String(localized: "brew が見つかりませんでした。") }
        let relevantLines = result.stderr
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return false }
                if trimmed.hasPrefix("Warning:") { return false }
                if trimmed.contains("Please report this issue to") { return false }
                if trimmed.hasSuffix(".rb") || trimmed.contains(".rb:") { return false }
                return true
            }

        if relevantLines.contains(where: { $0.localizedCaseInsensitiveContains("Full Disk Access") }) {
            return String(localized: "Homebrewがファイルを削除できませんでした。システム設定 > プライバシーとセキュリティ > フルディスクアクセス で Vestige を許可してから再試行してください。")
        }

        let message = relevantLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? String(localized: "brew の実行に失敗しました（詳細不明）。") : message
    }

    struct FormulaAppInfo {
        let formulaName: String
        let appPath: URL
    }

    /// Some Homebrew formulae (as opposed to casks) install a GUI .app straight into the
    /// Cellar rather than into /Applications — e.g. `brew install thock` vs. `brew install
    /// --cask thock`. These never appear in a Cask-only scan or a /Applications listing,
    /// so they're found by walking the Cellar directly rather than via `brew info --cask`.
    private static let knownCellarPaths = ["/opt/homebrew/Cellar", "/usr/local/Cellar"]

    static func installedFormulaApps() -> [FormulaAppInfo] {
        let fm = FileManager.default
        var results: [FormulaAppInfo] = []

        for cellarPath in knownCellarPaths {
            guard let formulaNames = try? fm.contentsOfDirectory(atPath: cellarPath) else { continue }
            for formulaName in formulaNames {
                let formulaDir = URL(fileURLWithPath: cellarPath).appendingPathComponent(formulaName)
                guard let versions = try? fm.contentsOfDirectory(at: formulaDir, includingPropertiesForKeys: nil) else { continue }
                for versionDir in versions {
                    guard let entries = try? fm.contentsOfDirectory(at: versionDir, includingPropertiesForKeys: nil) else { continue }
                    for entry in entries where entry.pathExtension == "app" {
                        results.append(FormulaAppInfo(formulaName: formulaName, appPath: entry))
                    }
                }
            }
        }
        return results
    }

    /// Runs `brew uninstall --force <name>` via the resolved `brew` binary.
    static func uninstallFormula(name: String) -> ProcessRunner.Result? {
        guard let brewPath = ProcessRunner.resolveExecutable("brew", knownPaths: knownBrewPaths) else { return nil }
        return ProcessRunner.run(brewPath, ["uninstall", "--force", name], timeout: 60)
    }
}
