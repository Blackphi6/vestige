import Foundation

enum BundleInfoReader {
    struct Info {
        let bundleID: String
        let version: String
    }

    static func read(appPath: URL) -> Info? {
        let plistPath = appPath.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let bundleID = plist["CFBundleIdentifier"] as? String
        else {
            return nil
        }
        let version = (plist["CFBundleShortVersionString"] as? String) ?? "—"
        return Info(bundleID: bundleID, version: version)
    }
}
