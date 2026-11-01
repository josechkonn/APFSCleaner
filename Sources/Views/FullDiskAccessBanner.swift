import SwiftUI

public struct FullDiskAccessBanner: View {
    public let fdaManager: FullDiskAccessManager

    public init(fdaManager: FullDiskAccessManager) {
        self.fdaManager = fdaManager
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Se requiere Acceso Total al Disco (Full Disk Access)")
                    .font(.subheadline.bold())
                Text("Otorga permisos en Ajustes del Sistema para permitir el análisis y limpieza de cachés y contenedores.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Abrir Ajustes") {
                fdaManager.openSystemSettingsPrivacy()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
    }
}
