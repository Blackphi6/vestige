import Foundation

enum DirectorySizeCalculator {
    /// Uses `/usr/bin/du -sk`, which is far faster than a Swift-side recursive walk
    /// for large cache directories.
    static func size(at url: URL) -> Int64? {
        let result = ProcessRunner.run("/usr/bin/du", ["-sk", url.path], timeout: 15)
        guard result.exitCode == 0 else { return nil }
        let firstField = result.stdout.split(separator: "\t").first ?? result.stdout.split(separator: " ").first ?? ""
        guard let kilobytes = Int64(firstField.trimmingCharacters(in: .whitespaces)) else { return nil }
        return kilobytes * 1024
    }
}
