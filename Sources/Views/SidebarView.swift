import SwiftUI

public struct SidebarView: View {
    @Bindable public var engine: ScannerEngine

    public init(engine: ScannerEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Cabecera / Identidad (despejando semáforos de macOS)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AuraTheme.actionGradientPrimary)
                        .frame(width: 32, height: 32)
                        .shadow(color: AuraTheme.neonCyan.opacity(0.4), radius: 6)

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("APFS Aura")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Clean & Offload Pro")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 42)
            .padding(.bottom, 24)

            // MARK: - Navigation Rail Items
            VStack(spacing: 4) {
                ForEach(ScanCategory.allCases) { category in
                    let isSelected = engine.selectedCategory == category
                    let count = itemCount(for: category)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            engine.selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? AuraTheme.neonCyan : .white.opacity(0.7))
                                .frame(width: 22)

                            Text(category.rawValue)
                                .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.75))
                                .lineLimit(1)

                            Spacer()

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(isSelected ? 0.20 : 0.08))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? AuraTheme.glassSelected : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? AuraTheme.glassBorderSelected : Color.clear, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // MARK: - Pie de Navegación: Estado del Disco Externo
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                    .overlay(AuraTheme.glassBorder)
                    .padding(.horizontal, 16)

                if let extVol = engine.selectedExternalVolume {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AuraTheme.emeraldGreen)
                            .frame(width: 8, height: 8)
                            .shadow(color: AuraTheme.emeraldGreen.opacity(0.8), radius: 4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(extVol.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(extVol.formattedFreeSpace) libres · \(extVol.fileSystemType)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AuraTheme.neonCyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AuraTheme.glassFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AuraTheme.glassBorder, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 12)
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AuraTheme.solarAmber)
                            .frame(width: 8, height: 8)

                        Text("Sin disco externo APFS")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 240)
        .background(
            Color.black.opacity(0.20)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(AuraTheme.glassBorderSubtle)
                .frame(width: 0.5),
            alignment: .trailing
        )
    }

    private func itemCount(for category: ScanCategory) -> Int {
        if category == .smartClean {
            return engine.items.filter { $0.riskLevel == .safe }.count
        } else if category == .externalOffload {
            return engine.items.filter { $0.isOffloadable }.count
        } else {
            return engine.items.filter { $0.category == category }.count
        }
    }
}
