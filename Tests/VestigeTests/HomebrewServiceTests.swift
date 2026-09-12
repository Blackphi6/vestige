import XCTest
@testable import Vestige

final class HomebrewServiceTests: XCTestCase {
    func testFiltersUnrelatedTapWarnings() {
        let stderr = """
        Warning: Calling `postflight` is deprecated! Use `postflight_steps` instead.
        Please report this issue to the blackphi6/homebrew-skilldrop tap (not Homebrew/* repositories), or even better, submit a PR to fix it:
          /opt/homebrew/Library/Taps/blackphi6/homebrew-skilldrop/Casks/skilldrop.rb:16
        Error: Something actually went wrong.
        """
        let result = ProcessRunner.Result(exitCode: 1, stdout: "", stderr: stderr)
        let message = HomebrewService.cleanedErrorMessage(from: result)
        XCTAssertEqual(message, "Error: Something actually went wrong.")
    }

    func testTranslatesFullDiskAccessFailureToGuidance() {
        let stderr = "Error: Unable to remove some files. Please enable Full Disk Access for your terminal under System Settings → Privacy & Security → Full Disk Access."
        let result = ProcessRunner.Result(exitCode: 1, stdout: "", stderr: stderr)
        let message = HomebrewService.cleanedErrorMessage(from: result)
        XCTAssertTrue(message.contains("フルディスクアクセス"))
    }

    func testFallsBackWhenNothingRelevantSurvivesFiltering() {
        let stderr = """
        Warning: Calling `postflight` is deprecated! Use `postflight_steps` instead.
        Please report this issue to the blackphi6/homebrew-skilldrop tap (not Homebrew/* repositories), or even better, submit a PR to fix it:
          /opt/homebrew/Library/Taps/blackphi6/homebrew-skilldrop/Casks/skilldrop.rb:16
        """
        let result = ProcessRunner.Result(exitCode: 1, stdout: "", stderr: stderr)
        let message = HomebrewService.cleanedErrorMessage(from: result)
        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(message.contains("skilldrop"))
    }

    func testNilResultReportsBrewMissing() {
        let message = HomebrewService.cleanedErrorMessage(from: nil)
        XCTAssertFalse(message.isEmpty)
    }
}
