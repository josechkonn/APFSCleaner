import Foundation

public enum DeletionMode: Sendable {
    case trash
    case permanent
}

public struct DeletionErrorRecord: Identifiable, Sendable {
    public let id = UUID()
    public let itemURL: URL
    public let localizedError: String
    public let errorCode: Int
}

public struct DeletionReport: Sendable {
    public var deletedItemsCount: Int = 0
    public var freedBytes: Int64 = 0
    public var errors: [DeletionErrorRecord] = []

    public init(deletedItemsCount: Int = 0, freedBytes: Int64 = 0, errors: [DeletionErrorRecord] = []) {
        self.deletedItemsCount = deletedItemsCount
        self.freedBytes = freedBytes
        self.errors = errors
    }

    public var formattedFreedBytes: String {
        ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }
}
