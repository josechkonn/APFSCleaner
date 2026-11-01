import SwiftUI

public struct FileItemRowView: View {
    public let item: FileItem
    public let onToggle: () -> Void

    @State private var showInfoPopover = false

    public init(item: FileItem, onToggle: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Checkbox (deshabilitado si está protegido por el sistema)
            if item.isSystemProtected {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AuraTheme.coralRed.opacity(0.8))
                    .frame(width: 16)
            } else {
                Toggle("", isOn: Binding(
                    get: { item.isSelected },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            }

            // Icono de estado/acción
            Image(systemName: item.riskLevel.sfSymbol)
                .foregroundColor(item.riskLevel.color)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 18)

            // Información del archivo (Garantía de 1 sola línea)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if item.isSystemProtected {
                        Text("Protegido macOS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AuraTheme.coralRed)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuraTheme.coralRed.opacity(0.15))
                            .clipShape(Capsule())
                    } else if item.isOffloadable {
                        Text("Migrable")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AuraTheme.neonCyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuraTheme.neonCyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(item.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Tamaño formateado en SF Mono
            Text(item.formattedSize)
                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .frame(width: 85, alignment: .trailing)

            // Botón de información detallada
            Button {
                showInfoPopover.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfoPopover) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: item.riskLevel.sfSymbol)
                            .foregroundColor(item.riskLevel.color)
                        Text(item.riskLevel.rawValue)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                    }

                    Divider()

                    Text(item.impactDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let reason = item.protectionReason {
                        Text(reason)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AuraTheme.coralRed)
                            .padding(8)
                            .background(AuraTheme.coralRed.opacity(0.12))
                            .cornerRadius(8)
                    }

                    Text("Ruta en disco:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(item.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(14)
                .frame(width: 340)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(item.isSelected ? AuraTheme.glassSelected : AuraTheme.glassFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(item.isSelected ? AuraTheme.glassBorderSelected : AuraTheme.glassBorder, lineWidth: 0.5)
        )
    }
}
