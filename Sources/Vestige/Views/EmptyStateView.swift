import SwiftUI

/// macOS 13-compatible stand-in for `ContentUnavailableView` (macOS 14+).
struct EmptyStateView: View {
    // LocalizedStringKey (not String) so callers passing a string literal get it
    // looked up in Localizable.xcstrings instead of shown verbatim.
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
