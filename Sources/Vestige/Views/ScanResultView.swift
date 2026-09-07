import SwiftUI

struct ScanResultView: View {
    @ObservedObject var viewModel: AppUninstallerViewModel
    @State private var showConfirmSheet = false

    private var groupedResults: [(ScanCategory, [ResidueItem])] {
        let grouped = Dictionary(grouping: viewModel.scanResults, by: \.category)
        return ScanCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let app = viewModel.selectedApp {
                header(app: app)
                Divider()

                if viewModel.isScanning {
                    ProgressView("残留物をスキャン中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.scanResults.isEmpty {
                    EmptyStateView(title: "残留物は見つかりませんでした", systemImage: "checkmark.circle")
                } else {
                    resultList
                    Divider()
                    footer(app: app)
                }
            } else {
                EmptyStateView(title: "アプリを選択してください", systemImage: "sidebar.left")
            }
        }
        .sheet(isPresented: $showConfirmSheet) {
            if let app = viewModel.selectedApp {
                DeletionConfirmSheet(
                    app: app,
                    items: viewModel.scanResults.filter(\.isSelected),
                    disposition: viewModel.trashDisposition,
                    onConfirm: {
                        showConfirmSheet = false
                        Task { await viewModel.deleteSelected() }
                    },
                    onCancel: { showConfirmSheet = false }
                )
            }
        }
        .alert("エラーが発生しました", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func header(app: InstalledApp) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon).resizable().frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.title3.bold())
                Text(app.bundleID).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let summary = viewModel.lastDeletionSummary {
                Text(summary).font(.caption).foregroundStyle(.green)
            }
        }
        .padding()
    }

    private var resultList: some View {
        List {
            ForEach(groupedResults, id: \.0) { category, items in
                Section(category.displayName) {
                    ForEach(items) { item in
                        ScanResultRowView(item: item) {
                            viewModel.toggleSelection(id: item.id)
                        }
                    }
                }
            }
        }
    }

    private func footer(app: InstalledApp) -> some View {
        HStack {
            Button("すべて選択") { viewModel.setAllSelected(true) }
            Button("すべて解除") { viewModel.setAllSelected(false) }

            Spacer()

            Picker("", selection: $viewModel.trashDisposition) {
                ForEach(TrashDisposition.allCases, id: \.self) { disposition in
                    Text(disposition.displayName).tag(disposition)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)

            Text(ByteFormatter.string(for: viewModel.selectedItemsTotalSize))
                .foregroundStyle(.secondary)

            Button {
                showConfirmSheet = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView().controlSize(.small)
                } else {
                    Text("削除")
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.isDeleting || !viewModel.scanResults.contains { $0.isSelected })
        }
        .padding()
    }
}
