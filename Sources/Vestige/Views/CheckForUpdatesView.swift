import SwiftUI

/// Menu-command entry point. Rendered inside a `CommandGroup`, which sits outside the
/// window's view hierarchy — the actual result alert is presented from ContentView via
/// the shared `UpdateCheckViewModel` instead of here.
struct CheckForUpdatesView: View {
    @EnvironmentObject private var updateChecker: UpdateCheckViewModel

    var body: some View {
        Button(String(localized: "アップデートを確認…")) {
            updateChecker.check()
        }
        .disabled(updateChecker.isChecking)
    }
}
