import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppUninstallerViewModel()

    var body: some View {
        NavigationSplitView {
            AppListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            ScanResultView(viewModel: viewModel)
        }
        .frame(minWidth: 780, minHeight: 480)
    }
}
