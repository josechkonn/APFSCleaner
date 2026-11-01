import Foundation

public actor DeletionService {
    private let fileManager = FileManager.default

    public init() {}

    public func executeDeletion(
        items: [FileItem],
        mode: DeletionMode,
        onProgress: @Sendable @escaping (_ currentItem: String, _ progressRatio: Double) -> Void
    ) async -> DeletionReport {
        var report = DeletionReport()
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            let ratio = total > 0 ? Double(index + 1) / total : 1.0
            onProgress(item.name, ratio)

            do {
                try deleteSingleItem(at: item.url, mode: mode)
                report.deletedItemsCount += 1
                report.freedBytes += item.sizeInBytes
            } catch {
                let nsError = error as NSError
                let record = DeletionErrorRecord(
                    itemURL: item.url,
                    localizedError: nsError.localizedDescription,
                    errorCode: nsError.code
                )
                report.errors.append(record)
            }
        }

        return report
    }

    private func deleteSingleItem(at url: URL, mode: DeletionMode) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }

        unlockAndPrepareForDeletion(at: url)

        switch mode {
        case .trash:
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)

        case .permanent:
            try fileManager.removeItem(at: url)
        }
    }

    private func unlockAndPrepareForDeletion(at url: URL) {
        let path = url.path
        chflags(path, 0)
        
        let attributes = (try? fileManager.attributesOfItem(atPath: path)) ?? [:]
        if let currentPermissions = attributes[.posixPermissions] as? NSNumber {
            let updatedPermissions = currentPermissions.intValue | 0o200
            try? fileManager.setAttributes([.posixPermissions: updatedPermissions], ofItemAtPath: path)
        }

        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                for case let childURL as URL in enumerator {
                    chflags(childURL.path, 0)
                    if let childAttrs = try? fileManager.attributesOfItem(atPath: childURL.path),
                       let childPerms = childAttrs[.posixPermissions] as? NSNumber {
                        let updated = childPerms.intValue | 0o200
                        try? fileManager.setAttributes([.posixPermissions: updated], ofItemAtPath: childURL.path)
                    }
                }
            }
        }
    }
}
