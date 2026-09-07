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

    // Interpolating a ternary's raw string literal into a Text(_:) does not make that
    // literal a separate localization key — String(localized:) here does.
    private var revertibilityNote: String {
        disposition == .moveToTrash
            ? String(localized: "ゴミ箱から復元できます")
            : String(localized: "取り消せません")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("\(app.name) を削除しますか？", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            // String(items.count), not \(items.count) directly: an Int interpolation
            // compiles to a %lld placeholder, which wouldn't match the %@ key registered
            // in Localizable.xcstrings and would silently fall back to the source string.
            Text("以下 \(String(items.count)) 件、合計 \(ByteFormatter.string(for: totalSize)) を\(disposition.displayName)します。この操作は\(revertibilityNote)。")
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
                Button(disposition.displayName, role: .destructive, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
