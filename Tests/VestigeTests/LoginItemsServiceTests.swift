import XCTest
@testable import Vestige

final class LoginItemsServiceTests: XCTestCase {
    func testCacheIsValidJustAfterWriting() {
        let now = Date()
        XCTAssertTrue(LoginItemsService.isCacheValid(cachedAt: now, now: now))
    }

    func testCacheIsValidWithinSevenDays() {
        let now = Date()
        let cachedAt = now.addingTimeInterval(-6 * 24 * 60 * 60)
        XCTAssertTrue(LoginItemsService.isCacheValid(cachedAt: cachedAt, now: now))
    }

    func testCacheExpiresAfterSevenDays() {
        let now = Date()
        let cachedAt = now.addingTimeInterval(-8 * 24 * 60 * 60)
        XCTAssertFalse(LoginItemsService.isCacheValid(cachedAt: cachedAt, now: now))
    }
}
