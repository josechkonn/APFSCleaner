import Foundation

public enum ItemAction: String, CaseIterable, Identifiable, Sendable {
    case clean = "Limpiar"
    case offload = "Migrar a Externo"
    case keep = "Conservar Protegido"

    public var id: String { rawValue }
}

public struct FileItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let path: String
    public let sizeInBytes: Int64
    public let riskLevel: RiskLevel
    public let impactDescription: String
    public let category: ScanCategory
    public let lastModified: Date
    public var isSelected: Bool
    public let isOffloadable: Bool
    public let isSystemProtected: Bool
    public let protectionReason: String?
    public let suggestedAction: ItemAction

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        path: String,
        sizeInBytes: Int64,
        riskLevel: RiskLevel,
        impactDescription: String,
        category: ScanCategory,
        lastModified: Date,
        isSelected: Bool = false,
        isOffloadable: Bool = false,
        isSystemProtected: Bool = false,
        protectionReason: String? = nil,
        suggestedAction: ItemAction = .clean
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.path = path
        self.sizeInBytes = sizeInBytes
        self.riskLevel = riskLevel
        self.impactDescription = impactDescription
        self.category = category
        self.lastModified = lastModified
        self.isSelected = isSelected
        self.isOffloadable = isOffloadable
        self.isSystemProtected = isSystemProtected
        self.protectionReason = protectionReason
        self.suggestedAction = suggestedAction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
}
