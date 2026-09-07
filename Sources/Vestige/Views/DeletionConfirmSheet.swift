import SwiftUI

struct DeletionConfirmSheet: View {
    let app: InstalledApp
    let items: [ResidueItem]
    let disposition: TrashDisposition
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var totalSize: Int64 {
        items.reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("\(app.name) を削除しますか？", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("以下 \(items.count) 件、合計 \(ByteFormatter.string(for: totalSize)) を\(disposition == .moveToTrash ? "ゴミ箱に移動" : "完全に削除")します。この操作は\(disposition == .moveToTrash ? "ゴミ箱から復元できます" : "取り消せません")。")
                .font(.callout)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items) { item in
                        Text("• \(item.title)")
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)

            HStack {
                Spacer()
                Button("キャンセル", role: .cancel, action: onCancel)
                Button(disposition == .moveToTrash ? "ゴミ箱に移動" : "完全に削除", role: .destructive, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
