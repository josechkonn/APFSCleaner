import SwiftUI

public enum RiskLevel: String, CaseIterable, Identifiable, Sendable, Comparable {
    case safe = "Seguro"
    case moderate = "Precaución"
    case offload = "Migrable a Externo"
    case critical = "Protegido por Sistema"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .offload: return "externaldrive.fill.badge.plus"
        case .critical: return "lock.shield.fill"
        }
    }

    public var color: Color {
        switch self {
        case .safe: return AuraTheme.emeraldGreen
        case .moderate: return AuraTheme.solarAmber
        case .offload: return AuraTheme.neonCyan
        case .critical: return AuraTheme.coralRed
        }
    }

    private var sortOrder: Int {
        switch self {
        case .safe: return 0
        case .offload: return 1
        case .moderate: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
