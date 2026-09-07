import XCTest
@testable import Vestige

final class ResidueItemTests: XCTestCase {
    func testDefaultsToSelectedForAutoRemovableCategory() {
        let item = ResidueItem(
            category: .tccPermissions,
            title: "Accessibility permission",
            detail: "tccutil reset Accessibility dev.example.App",
            action: .resetTCCService(service: "Accessibility")
        )
        XCTAssertTrue(item.isSelected, "TCC items should default to selected like every other auto-removable category")
    }

    func testSystemLaunchItemsAreNeverSelectedRegardlessOfCallerIntent() {
        let item = ResidueItem(
            category: .systemLaunchItems,
            title: "com.example.daemon",
            detail: "/Library/LaunchDaemons/com.example.daemon.plist",
            action: .manualReviewOnly(URL(fileURLWithPath: "/Library/LaunchDaemons/com.example.daemon.plist")),
            isSelected: true
        )
        XCTAssertFalse(item.isSelected, "System launch items require manual review and must never be auto-selected")
    }
}
