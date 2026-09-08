import XCTest
@testable import Vestige

final class UpdateCheckerTests: XCTestCase {
    func testDetectsNewerPatchVersion() {
        XCTAssertTrue(UpdateChecker.isNewer("0.2.10", than: "0.2.9"))
    }

    func testDetectsNewerMinorVersion() {
        XCTAssertTrue(UpdateChecker.isNewer("0.3.0", than: "0.2.10"))
    }

    func testEqualVersionsAreNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer("0.3.0", than: "0.3.0"))
    }

    func testOlderVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer("0.2.0", than: "0.3.0"))
    }

    func testTreatsMissingTrailingComponentsAsZero() {
        XCTAssertFalse(UpdateChecker.isNewer("1.2", than: "1.2.0"))
        XCTAssertTrue(UpdateChecker.isNewer("1.2.1", than: "1.2"))
    }
}
