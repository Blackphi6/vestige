import Foundation

/// Insurance sweep: catches stray files a known-category scan missed, via Spotlight.
enum MDFindService {
    static func searchByBundleID(_ bundleID: String) -> [String] {
        guard let mdfindPath = ProcessRunner.resolveExecutable("mdfind", knownPaths: ["/usr/bin/mdfind"]) else { return [] }
        let query = "kMDItemCFBundleIdentifier == '\(bundleID)' || kMDItemContentTypeTree == '\(bundleID)'"
        let result = ProcessRunner.run(mdfindPath, [query], timeout: 10)
        guard result.exitCode == 0 else { return [] }
        return result.stdout
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
