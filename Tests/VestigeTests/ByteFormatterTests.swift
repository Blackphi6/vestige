import XCTest
@testable import Vestige

final class ByteFormatterTests: XCTestCase {
    func testNilReturnsPlaceholder() {
        XCTAssertEqual(ByteFormatter.string(for: nil), "—")
    }

    func testZeroBytes() {
        XCTAssertFalse(ByteFormatter.string(for: 0).isEmpty)
    }

    func testFormatsMegabytes() {
        let result = ByteFormatter.string(for: 5_000_000)
        XCTAssertTrue(result.contains("MB"), "Expected MB unit in \(result)")
    }
}
