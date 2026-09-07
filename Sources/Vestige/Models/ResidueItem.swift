import Foundation

enum ResidueAction: Sendable {
    case deleteFile(URL)
    case uninstallHomebrewCask(token: String)
    case resetTCCService(service: String)
    case manualReviewOnly(URL)
    case informational
}

struct ResidueItem: Identifiable, Sendable {
    let id: String
    let category: ScanCategory
    let title: String
    let detail: String
    let sizeBytes: Int64?
    let action: ResidueAction
    var isSelected: Bool

    init(
        category: ScanCategory,
        title: String,
        detail: String,
        sizeBytes: Int64? = nil,
        action: ResidueAction,
        isSelected: Bool = true
    ) {
        self.id = "\(category.rawValue)|\(detail)"
        self.category = category
        self.title = title
        self.detail = detail
        self.sizeBytes = sizeBytes
        self.action = action
        self.isSelected = isSelected && category.isAutoRemovable
    }
}
