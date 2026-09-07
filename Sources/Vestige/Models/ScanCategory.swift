import Foundation

enum ScanCategory: String, CaseIterable, Sendable {
    case applicationSupport = "Application Support"
    case preferences = "Preferences"
    case caches = "Caches"
    case httpStorages = "HTTP Storages"
    case containers = "Containers"
    case savedState = "Saved Application State"
    case webKit = "WebKit"
    case logs = "Logs"
    case launchAgents = "Login Items (User)"
    case systemLaunchItems = "Login Items (System, manual removal required)"
    case homebrewCask = "Homebrew Cask"
    case tccPermissions = "Privacy Permissions (TCC)"
    case other = "Other"

    var isAutoRemovable: Bool {
        self != .systemLaunchItems
    }
}
