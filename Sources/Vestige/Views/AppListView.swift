import SwiftUI

struct AppListView: View {
    @ObservedObject var viewModel: AppUninstallerViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingApps {
                ProgressView("アプリを検索中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredApps, selection: Binding(
                    get: { viewModel.selectedApp?.id },
                    set: { newID in
                        if let app = viewModel.installedApps.first(where: { $0.id == newID }) {
                            viewModel.selectApp(app)
                        }
                    }
                )) { app in
                    AppRowView(app: app)
                        .tag(app.id)
                }
                .listStyle(.sidebar)
            }
        }
        .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "アプリを検索")
        .navigationTitle("Vestige")
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.loadApps()
                } label: {
                    Label("再スキャン", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoadingApps)
            }
        }
        .task {
            if viewModel.installedApps.isEmpty {
                viewModel.loadApps()
            }
        }
    }
}
