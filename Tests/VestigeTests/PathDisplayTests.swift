import XCTest
@testable import Vestige

final class PathDisplayTests: XCTestCase {
    func testCollapsesHomeDirectoryPrefix() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertEqual(PathDisplay.string(for: "\(home)/Library/Caches/foo"), "~/Library/Caches/foo")
    }

    func testHomeDirectoryItselfBecomesTilde() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertEqual(PathDisplay.string(for: home), "~")
    }

    func testLeavesUnrelatedPathsUntouched() {
        XCTAssertEqual(PathDisplay.string(for: "/Library/LaunchAgents/foo.plist"), "/Library/LaunchAgents/foo.plist")
    }

    func testDoesNotCollapseSimilarlyPrefixedSiblingDirectory() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let sibling = "\(home)-backup/Library/foo"
        XCTAssertEqual(PathDisplay.string(for: sibling), sibling)
    }
}
