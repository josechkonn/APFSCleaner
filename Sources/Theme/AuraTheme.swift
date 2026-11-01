import SwiftUI

public enum AuraTheme {
    // MARK: - Lienzo Cósmico CleanMyMac 5 (Dark Cosmic Canvas)
    public static let bgDeepMidnight = Color(red: 0.04, green: 0.05, blue: 0.11) // #0A0D1C
    public static let bgRoyalIndigo  = Color(red: 0.09, green: 0.06, blue: 0.22) // #171038
    public static let bgCosmicPlum   = Color(red: 0.16, green: 0.05, blue: 0.28) // #290D47
    public static let bgAccentGlow   = Color(red: 0.52, green: 0.15, blue: 0.90) // #8526E6

    // MARK: - Acentos Neón Vibrantes
    public static let neonCyan        = Color(red: 0.00, green: 0.89, blue: 1.00) // #00E5FF
    public static let electricIndigo  = Color(red: 0.45, green: 0.35, blue: 1.00) // #7359FF
    public static let auroraMagenta   = Color(red: 0.88, green: 0.15, blue: 0.82) // #E026D1
    public static let emeraldGreen    = Color(red: 0.12, green: 0.88, blue: 0.55) // #1FE08C
    public static let solarAmber      = Color(red: 1.00, green: 0.72, blue: 0.18) // #FFB82E
    public static let coralRed        = Color(red: 1.00, green: 0.28, blue: 0.42) // #FF476B
    public static let externalBlue    = Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6

    // MARK: - Superficies de Cristal (Glassmorphic)
    public static let glassFill            = Color.white.opacity(0.07)
    public static let glassSelected        = Color.white.opacity(0.16)
    public static let glassHover           = Color.white.opacity(0.10)
    public static let glassBorder          = Color.white.opacity(0.12)
    public static let glassBorderSelected  = Color.white.opacity(0.28)
    public static let glassBorderSubtle    = Color.white.opacity(0.06)

    // MARK: - Gradientes de Acción
    public static let actionGradientPrimary = LinearGradient(
        colors: [neonCyan, electricIndigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let offloadGradientPrimary = LinearGradient(
        colors: [externalBlue, neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let purgeGradientDestructive = LinearGradient(
        colors: [coralRed, auroraMagenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct CosmicCanvasBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [AuraTheme.bgDeepMidnight, AuraTheme.bgRoyalIndigo, AuraTheme.bgCosmicPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [AuraTheme.bgAccentGlow.opacity(0.40), Color.clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 700
            )
            RadialGradient(
                colors: [AuraTheme.neonCyan.opacity(0.18), Color.clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 550
            )
        }
        .ignoresSafeArea()
    }
}

public struct GlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 14
    public var isSelected: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? AuraTheme.glassSelected : AuraTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? AuraTheme.glassBorderSelected : AuraTheme.glassBorder, lineWidth: 0.5)
            )
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 14, isSelected: Bool = false) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, isSelected: isSelected))
    }
}
