import Foundation
import SwiftUI

@MainActor
final class AppUninstallerViewModel: ObservableObject {
    @Published private(set) var installedApps: [InstalledApp] = []
    @Published var searchText: String = ""
    @Published var selectedApp: InstalledApp?
    @Published private(set) var scanResults: [ResidueItem] = []
    @Published private(set) var isLoadingApps = false
    @Published private(set) var isScanning = false
    @Published private(set) var isDeleting = false
    @Published var trashDisposition: TrashDisposition = .moveToTrash
    @Published var errorMessage: String?
    @Published private(set) var lastDeletionSummary: String?

    var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return installedApps }
        return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var selectedItemsTotalSize: Int64 {
        scanResults.filter(\.isSelected).reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    func loadApps() {
        isLoadingApps = true
        Task.detached(priority: .userInitiated) {
            let apps = AppDiscoveryService.discoverInstalledApps()
            await MainActor.run {
                self.installedApps = apps
                self.isLoadingApps = false
            }
        }
    }

    func selectApp(_ app: InstalledApp) {
        selectedApp = app
        scanResults = []
        lastDeletionSummary = nil
        isScanning = true
        Task.detached(priority: .userInitiated) {
            let results = ResidueScanner.scan(for: app)
            await MainActor.run {
                guard self.selectedApp?.id == app.id else { return }
                self.scanResults = results
                self.isScanning = false
            }
        }
    }

    func toggleSelection(id: String) {
        guard let index = scanResults.firstIndex(where: { $0.id == id }) else { return }
        scanResults[index].isSelected.toggle()
    }

    func setAllSelected(_ selected: Bool) {
        for index in scanResults.indices where scanResults[index].category.isAutoRemovable {
            scanResults[index].isSelected = selected
        }
    }

    func deleteSelected() async {
        let toRemove = scanResults.filter(\.isSelected)
        guard !toRemove.isEmpty else { return }

        isDeleting = true
        errorMessage = nil
        var failures: [String] = []
        var succeededCount = 0

        for item in toRemove {
            do {
                try await performAction(item.action)
                succeededCount += 1
            } catch {
                failures.append("\(item.title): \(error.localizedDescription)")
            }
        }

        isDeleting = false
        lastDeletionSummary = "\(succeededCount) 件を処理しました。"
        if !failures.isEmpty {
            errorMessage = failures.joined(separator: "\n")
        }

        if let app = selectedApp {
            selectApp(app)
        }
        loadApps()
    }

    private func performAction(_ action: ResidueAction) async throws {
        switch action {
        case .deleteFile(let url):
            try TrashService.remove(url: url, disposition: trashDisposition)
        case .uninstallHomebrewCask(let token):
            let result = HomebrewService.uninstallCask(token: token)
            if result == nil || result?.exitCode != 0 {
                throw ActionError.commandFailed(result?.stderr ?? "brew not found")
            }
        case .resetTCCService(let service):
            guard let app = selectedApp else { return }
            _ = TCCService.reset(service: service, bundleID: app.bundleID)
        case .manualReviewOnly, .informational:
            break
        }
    }

    enum ActionError: LocalizedError {
        case commandFailed(String)
        var errorDescription: String? {
            switch self {
            case .commandFailed(let message): return message
            }
        }
    }
}
