import SwiftUI

public struct StorageSummaryView: View {
    @Bindable public var engine: ScannerEngine
    public let onInitiateClean: (DeletionMode) -> Void

    public init(engine: ScannerEngine, onInitiateClean: @escaping (DeletionMode) -> Void) {
        self.engine = engine
        self.onInitiateClean = onInitiateClean
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Espacio Seleccionado para Liberar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteCountFormatter.string(fromByteCount: engine.totalSelectedBytes, countStyle: .file))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Total encontrado: \(ByteCountFormatter.string(fromByteCount: engine.totalBytesFound, countStyle: .file))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    Button {
                        onInitiateClean(.trash)
                    } label: {
                        Label("Mover a la Papelera", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        onInitiateClean(.permanent)
                    } label: {
                        Label("Eliminación Permanente", systemImage: "xmark.bin")
                    }
                } label: {
                    Label("Limpiar Seleccionados", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(engine.totalSelectedBytes == 0 || engine.isScanning)
            }
        }
    }
}
