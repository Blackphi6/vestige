import SwiftUI

struct ScanResultRowView: View {
    let item: ResidueItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: Binding(get: { item.isSelected }, set: { _ in onToggle() }))
                .labelsHidden()
                .disabled(!item.category.isAutoRemovable)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                Text(item.detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if let size = item.sizeBytes {
                Text(ByteFormatter.string(for: size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
