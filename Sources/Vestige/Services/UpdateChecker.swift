import Foundation

/// Checks GitHub Releases for a newer version and hands back a URL to open in the
/// browser — it never downloads or installs anything. Vestige ships ad-hoc signed (no
/// Apple Developer Program membership), so any updater that tries to download-and-verify-
/// and-install a new build risks failing code signature checks. Pointing the user at the
/// releases page (or `brew upgrade` for Homebrew installs) sidesteps that entirely.
enum UpdateChecker {
    struct UpdateInfo {
        let latestVersion: String
        let releaseURL: URL
    }

    enum Result {
        case updateAvailable(UpdateInfo)
        case upToDate
        case failed
    }

    private static let apiURL = URL(string: "https://api.github.com/repos/Blackphi6/vestige/releases/latest")!
    private static let releasesPageURL = URL(string: "https://github.com/Blackphi6/vestige/releases/latest")!

    static func checkForUpdate() async -> Result {
        guard let (data, response) = try? await URLSession.shared.data(from: apiURL),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String
        else { return .failed }

        let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        guard isNewer(latestVersion, than: currentVersion) else { return .upToDate }
        return .updateAvailable(UpdateInfo(latestVersion: latestVersion, releaseURL: releasesPageURL))
    }

    /// Dot-separated numeric comparison, e.g. "0.3.0" > "0.2.10" > "0.2.9". Missing
    /// trailing components are treated as 0 (so "1.2" == "1.2.0").
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let count = max(candidateParts.count, currentParts.count)
        for index in 0..<count {
            let candidatePart = index < candidateParts.count ? candidateParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if candidatePart != currentPart { return candidatePart > currentPart }
        }
        return false
    }
}
