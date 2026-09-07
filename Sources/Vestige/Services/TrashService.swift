import Foundation

enum TrashDisposition: String, CaseIterable, Sendable {
    case moveToTrash = "Move to Trash"
    case deletePermanently = "Delete Permanently"
}

enum RemovalOutcome: Sendable {
    case movedToTrash
    case deletedPermanently
}

enum TrashService {
    enum TrashError: LocalizedError {
        case failed(path: String, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .failed(let path, let underlying):
                let nsError = underlying as NSError
                // Some system-managed paths (e.g. ~/Library/Containers/<bundle-id>) refuse
                // access without Full Disk Access, even when normal file permissions allow it.
                if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileWriteNoPermissionError || nsError.code == NSFileReadNoPermissionError {
                    return "\(path): アクセス権限がありません。システム設定 > プライバシーとセキュリティ > フルディスクアクセス で Vestige を許可してから再試行してください。"
                }
                return "Failed to remove \(path): \(underlying.localizedDescription)"
            }
        }
    }

    /// macOS refuses to move some system-managed paths (e.g. an app's
    /// `~/Library/Containers/<bundle-id>`, which is owned by containermanagerd) to the
    /// Trash even with the right permissions, while a direct delete of the same path
    /// succeeds. When that happens under `.moveToTrash`, fall back to a permanent delete
    /// rather than surfacing a confusing error for something we can actually clean up.
    @discardableResult
    static func remove(url: URL, disposition: TrashDisposition) throws -> RemovalOutcome {
        switch disposition {
        case .deletePermanently:
            do {
                try FileManager.default.removeItem(at: url)
                return .deletedPermanently
            } catch {
                throw TrashError.failed(path: url.path, underlying: error)
            }
        case .moveToTrash:
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                return .movedToTrash
            } catch {
                do {
                    try FileManager.default.removeItem(at: url)
                    return .deletedPermanently
                } catch {
                    throw TrashError.failed(path: url.path, underlying: error)
                }
            }
        }
    }
}
