import XCTest
@testable import Vestige

final class ResidueScannerTests: XCTestCase {
    private func makeApp(name: String = "Thock", bundleID: String = "dev.kamillobinski.Thock") -> InstalledApp {
        InstalledApp(
            id: bundleID,
            name: name,
            bundleID: bundleID,
            version: "1.0",
            appPath: URL(fileURLWithPath: "/Applications/\(name).app"),
            source: .applications,
            homebrewCaskToken: nil,
            homebrewZapTrashPatterns: []
        )
    }

    func testGroupContainerSuffixUsesLastBundleIDComponent() {
        XCTAssertEqual(ResidueScanner.groupContainerSuffix(bundleID: "dev.kamillobinski.Thock"), "Thock")
        XCTAssertEqual(ResidueScanner.groupContainerSuffix(bundleID: "SingleWord"), "SingleWord")
        XCTAssertEqual(ResidueScanner.groupContainerSuffix(bundleID: ""), "")
    }

    func testLaunchItemFileNameMatchesBundleID() {
        let app = makeApp()
        XCTAssertTrue(LaunchItemScanner.matches(fileName: "dev.kamillobinski.thock.plist", app: app))
    }

    func testLaunchItemFileNameIgnoresShortUnrelatedNames() {
        let shortNamedApp = makeApp(name: "Go", bundleID: "com.example.go")
        XCTAssertFalse(LaunchItemScanner.matches(fileName: "com.apple.something.plist", app: shortNamedApp))
    }

    func testLaunchItemFileNameDoesNotMatchUnrelatedPlist() {
        let app = makeApp()
        XCTAssertFalse(LaunchItemScanner.matches(fileName: "com.apple.finder.plist", app: app))
    }
}
