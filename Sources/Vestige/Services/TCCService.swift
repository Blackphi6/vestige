import Foundation

/// Resets macOS Privacy (TCC) permission grants for an app via `tccutil`.
/// TCC.db itself is SIP-protected and unreadable without Full Disk Access, so we
/// cannot detect which grants exist — we offer a reset action per common service instead.
enum TCCService {
    static let commonServices = [
        "Accessibility",
        "Microphone",
        "Camera",
        "ScreenCapture",
        "SystemPolicyAllFiles",
        "AppleEvents",
    ]

    static func reset(service: String, bundleID: String) -> ProcessRunner.Result? {
        guard let tccutilPath = ProcessRunner.resolveExecutable("tccutil", knownPaths: ["/usr/bin/tccutil"]) else { return nil }
        return ProcessRunner.run(tccutilPath, ["reset", service, bundleID], timeout: 10)
    }
}
