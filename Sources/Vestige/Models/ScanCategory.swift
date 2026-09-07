import Foundation

enum ScanCategory: String, CaseIterable, Sendable {
    case appBundle = "App Bundle"
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

    /// rawValue stays English and doubles as a stable identifier (used in
    /// ResidueItem.id and the zap-path category heuristic); this is what's shown in the UI.
    var displayName: String {
        switch self {
        case .appBundle: return String(localized: "アプリ本体")
        case .applicationSupport: return String(localized: "Application Support")
        case .preferences: return String(localized: "環境設定")
        case .caches: return String(localized: "キャッシュ")
        case .httpStorages: return String(localized: "HTTP Storages")
        case .containers: return String(localized: "コンテナ")
        case .savedState: return String(localized: "保存済みの状態")
        case .webKit: return String(localized: "WebKit")
        case .logs: return String(localized: "ログ")
        case .launchAgents: return String(localized: "ログイン項目（ユーザー）")
        case .systemLaunchItems: return String(localized: "ログイン項目（システム、手動削除が必要）")
        case .homebrewCask: return String(localized: "Homebrew Cask")
        case .tccPermissions: return String(localized: "プライバシー権限 (TCC)")
        case .other: return String(localized: "その他")
        }
    }
}
