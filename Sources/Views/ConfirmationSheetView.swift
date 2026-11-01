import SwiftUI

public enum OperationKind: Sendable {
    case clean(DeletionMode)
    case offload(ExternalVolume)
}

public struct ConfirmationSheetView: View {
    @Bindable public var engine: ScannerEngine
    public let operation: OperationKind
    public let onConfirm: () -> Void
    public let onCancel: () -> Void

    public init(
        engine: ScannerEngine,
        operation: OperationKind,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.engine = engine
        self.operation = operation
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            AuraTheme.bgDeepMidnight.ignoresSafeArea()

            VStack(spacing: 20) {
                // Icono de cabecera con resplandor
                ZStack {
                    Circle()
                        .fill(headerGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: headerColor.opacity(0.5), radius: 12)

                    Image(systemName: headerIcon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)

                VStack(spacing: 6) {
                    Text(headerTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(headerSubtitle)
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Resumen de espacio y destino
                VStack(spacing: 12) {
                    HStack {
                        Text("Espacio a liberar en Mac:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: engine.totalSelectedBytes, countStyle: .file))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(AuraTheme.neonCyan)
                    }

                    if case .offload(let volume) = operation {
                        Divider().overlay(AuraTheme.glassBorder)
                        HStack {
                            Text("Destino de respaldo:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(volume.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AuraTheme.emeraldGreen)
                        }
                    }
                }
                .padding(14)
                .background(AuraTheme.glassFill)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AuraTheme.glassBorder, lineWidth: 0.5))
                .padding(.horizontal, 24)

                // Botones de acción
                HStack(spacing: 14) {
                    Button("Cancelar") {
                        onCancel()
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AuraTheme.glassFill)
                    .cornerRadius(10)

                    Button(action: onConfirm) {
                        Text(actionButtonTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(headerGradient)
                            .cornerRadius(10)
                            .shadow(color: headerColor.opacity(0.4), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.bottom, 12)
            }
            .padding(16)
        }
        .frame(width: 440, height: 340)
    }

    private var headerIcon: String {
        switch operation {
        case .clean: return "sparkles"
        case .offload: return "externaldrive.badge.timemachine"
        }
    }

    private var headerColor: Color {
        switch operation {
        case .clean: return AuraTheme.neonCyan
        case .offload: return AuraTheme.emeraldGreen
        }
    }

    private var headerGradient: LinearGradient {
        switch operation {
        case .clean: return AuraTheme.actionGradientPrimary
        case .offload: return AuraTheme.offloadGradientPrimary
        }
    }

    private var headerTitle: String {
        switch operation {
        case .clean: return "Confirmar Limpieza Segura"
        case .offload: return "Confirmar Migración al Disco Externo"
        }
    }

    private var headerSubtitle: String {
        switch operation {
        case .clean:
            return "Se eliminarán los archivos y cachés temporales seleccionados. Las aplicaciones recrearán sus cachés cuando sea necesario."
        case .offload(let volume):
            return "Los archivos se copiarán de forma segura a '\(volume.name)' y se creará un enlace simbólico automático en tu Mac para que sigan accesibles."
        }
    }

    private var actionButtonTitle: String {
        switch operation {
        case .clean(let mode):
            return mode == .trash ? "Mover a la Papelera" : "Eliminar Definitivamente"
        case .offload:
            return "Iniciar Migración"
        }
    }
}
