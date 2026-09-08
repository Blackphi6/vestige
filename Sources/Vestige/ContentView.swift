import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppUninstallerViewModel()
    @EnvironmentObject private var updateChecker: UpdateCheckViewModel

    var body: some View {
        NavigationSplitView {
            AppListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            ScanResultView(viewModel: viewModel)
        }
        .frame(minWidth: 780, minHeight: 480)
        .alert(item: $updateChecker.alertKind) { kind in
            switch kind {
            case .updateAvailable(let info):
                return Alert(
                    title: Text(String(localized: "新しいバージョンがあります")),
                    message: Text("Vestige \(info.latestVersion)"),
                    primaryButton: .default(Text(String(localized: "リリースページを開く"))) {
                        NSWorkspace.shared.open(info.releaseURL)
                    },
                    secondaryButton: .cancel(Text(String(localized: "キャンセル")))
                )
            case .upToDate:
                return Alert(title: Text(String(localized: "お使いのバージョンは最新です")))
            case .failed:
                return Alert(
                    title: Text(String(localized: "確認できませんでした")),
                    message: Text(String(localized: "インターネット接続を確認して、もう一度お試しください。"))
                )
            }
        }
    }
}
