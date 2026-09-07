import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Expands a `~`/glob pattern (as used in Homebrew Cask `zap` stanzas) to the paths
/// that currently exist on disk.
enum GlobResolver {
    static func resolve(_ pattern: String) -> [String] {
        var globResult = glob_t()
        defer { globfree(&globResult) }

        let flags = GLOB_TILDE | GLOB_NOSORT
        let status = pattern.withCString { cPattern in
            glob(cPattern, flags, nil, &globResult)
        }
        guard status == 0 else { return [] }

        let count = Int(globResult.gl_matchc)
        return (0..<count).compactMap { index in
            guard let cPath = globResult.gl_pathv[index] else { return nil }
            return String(cString: cPath)
        }
    }
}
