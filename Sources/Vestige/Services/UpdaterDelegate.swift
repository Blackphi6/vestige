import AppKit
import Sparkle

/// Vestige ships ad-hoc signed (no Apple Developer Program membership), so Sparkle's
/// automatic download-and-install can fail code signature validation against the
/// currently-running app. When the update cycle aborts with an error, fall back to
/// pointing the user at the GitHub Releases page instead of leaving them with an
/// opaque failure and no path forward.
final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private static let releasesURL = URL(string: "https://github.com/Blackphi6/vestige/releases/latest")!

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let nsError = error as NSError
        // "No update available" surfaces through this same delegate method; that's not
        // a failure worth interrupting the user for.
        guard nsError.domain == SUSparkleErrorDomain, nsError.code != SUError.noUpdateError.rawValue else { return }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = String(localized: "自動アップデートに失敗しました")
            alert.informativeText = String(localized: "GitHubのリリースページから手動でダウンロードしてください。")
            alert.addButton(withTitle: String(localized: "リリースページを開く"))
            alert.addButton(withTitle: String(localized: "キャンセル"))
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(Self.releasesURL)
            }
        }
    }
}
