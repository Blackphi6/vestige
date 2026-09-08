import SwiftUI

/// Menu commands render outside the main window's view hierarchy, so a `.alert` attached
/// directly to a `CommandGroup` view never appears. This shared, environment-injected
/// object lets the menu command trigger a check while the actual alert is presented from
/// ContentView, which does have a window to present into.
@MainActor
final class UpdateCheckViewModel: ObservableObject {
    @Published private(set) var isChecking = false
    @Published var alertKind: UpdateAlertKind?

    func check() {
        isChecking = true
        Task {
            let result = await UpdateChecker.checkForUpdate()
            isChecking = false
            switch result {
            case .updateAvailable(let info): alertKind = .updateAvailable(info)
            case .upToDate: alertKind = .upToDate
            case .failed: alertKind = .failed
            }
        }
    }
}

enum UpdateAlertKind: Identifiable {
    case updateAvailable(UpdateChecker.UpdateInfo)
    case upToDate
    case failed

    var id: String {
        switch self {
        case .updateAvailable(let info): return "update-\(info.latestVersion)"
        case .upToDate: return "up-to-date"
        case .failed: return "failed"
        }
    }
}
