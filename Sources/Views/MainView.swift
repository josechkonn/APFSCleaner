import SwiftUI

public struct MainView: View {
    @State private var engine = ScannerEngine()
    @State private var fdaManager = FullDiskAccessManager()
    @State private var showConfirmDialog = false
    @State private var currentOperation: OperationKind = .clean(.trash)
    @State private var showResultAlert = false
    @State private var resultAlertMessage = ""

    public init() {}

    public var body: some View {
        ZStack {
            // MARK: - 1. Lienzo Cósmico Full-Bleed
            CosmicCanvasBackground()

            HStack(spacing: 0) {
                // MARK: - 2. Navigation Rail de Cristal
                SidebarView(engine: engine)

                // MARK: - 3. Área Central y Hero
                VStack(spacing: 0) {
                    // Barra Superior Despejada (sin toolbar genérica)
                    topNavigationHeader
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)

                    Divider()
                        .overlay(AuraTheme.glassBorder)

                    // Filtros y Barra de Estado Rápido
                    filterAndStatusBar
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)

                    Divider()
                        .overlay(AuraTheme.glassBorderSubtle)

                    // Contenido Principal / Lista de Tarjetas Glassmorphic
                    ZStack {
                        if engine.isScanning {
                            scanningProgressHero
                        } else if engine.filteredItems.isEmpty {
                            emptyStateHero
                        } else {
                            itemsScrollView
                        }

                        // MARK: - 5. Botón Maestro Flotante Neon
                        VStack {
                            Spacer()
                            floatingMasterBar
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 1060, minHeight: 680)
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationSheetView(
                engine: engine,
                operation: currentOperation,
                onConfirm: {
                    showConfirmDialog = false
                    executeOperation()
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
        .alert("Operación Completada", isPresented: $showResultAlert) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(resultAlertMessage)
        }
        .task {
            fdaManager.checkPermission()
            await engine.startFullScan()
        }
    }

    // MARK: - Subcomponentes

    private var topNavigationHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(engine.selectedCategory?.rawValue ?? "Vista General")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(headerDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            // Botón de re-escaneo circular de cristal
            Button {
                Task {
                    await engine.startFullScan()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(engine.isScanning ? 360 : 0))
                        .animation(engine.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: engine.isScanning)

                    Text(engine.isScanning ? "Analizando..." : "Escanear Todo")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AuraTheme.glassFill)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AuraTheme.glassBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(engine.isScanning)
        }
    }

    private var filterAndStatusBar: some View {
        HStack(spacing: 12) {
            // Filtro de Riesgo
            Picker("Filtrar:", selection: $engine.selectedRiskFilter) {
                Text("Todos los niveles").tag(RiskLevel?.none)
                ForEach(RiskLevel.allCases) { risk in
                    Label(risk.rawValue, systemImage: risk.sfSymbol)
                        .tag(RiskLevel?.some(risk))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 190)

            Spacer()

            Button("Seleccionar Seguros (🟢)") {
                engine.selectAllFiltered(onlySafe: true)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AuraTheme.emeraldGreen)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AuraTheme.emeraldGreen.opacity(0.12))
            .cornerRadius(8)

            Button("Deseleccionar") {
                engine.deselectAllFiltered()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AuraTheme.glassFill)
            .cornerRadius(8)
        }
    }

    private var itemsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(engine.filteredItems) { item in
                    FileItemRowView(item: item) {
                        engine.toggleSelection(for: item.id)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 100) // Espacio para el botón flotante
        }
    }

    private var emptyStateHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AuraTheme.emeraldGreen.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 42))
                    .foregroundColor(AuraTheme.emeraldGreen)
                    .shadow(color: AuraTheme.emeraldGreen.opacity(0.6), radius: 14)
            }

            VStack(spacing: 6) {
                Text("Volumen Optimizado")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("No hay residuos pendientes en esta categoría. Tu disco APFS se encuentra limpio.")
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    private var scanningProgressHero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AuraTheme.actionGradientPrimary)
                    .frame(width: 80, height: 80)
                    .shadow(color: AuraTheme.neonCyan.opacity(0.5), radius: 16)

                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .tint(.white)
            }

            VStack(spacing: 6) {
                Text("Escaneando Estructura APFS...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(engine.currentScanningPath)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 450)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    // MARK: - Botón Maestro Flotante con Brillo Neón
    private var floatingMasterBar: some View {
        HStack(spacing: 16) {
            // Acción A: Limpiar Seguros
            Button {
                currentOperation = .clean(.trash)
                showConfirmDialog = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text("Limpiar Seleccionados (\(ByteCountFormatter.string(fromByteCount: engine.totalSelectedBytes, countStyle: .file)))")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AuraTheme.actionGradientPrimary)
                .clipShape(Capsule())
                .shadow(color: AuraTheme.neonCyan.opacity(0.45), radius: 14, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(engine.totalSelectedBytes == 0 || engine.isScanning)

            // Acción B: Migrar a Disco Externo (si hay disco externo y elementos migrables)
            if let volume = engine.selectedExternalVolume {
                Button {
                    currentOperation = .offload(volume)
                    showConfirmDialog = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .font(.system(size: 14, weight: .bold))
                        Text("Migrar a \(volume.name)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(AuraTheme.offloadGradientPrimary)
                    .clipShape(Capsule())
                    .shadow(color: AuraTheme.externalBlue.opacity(0.45), radius: 14, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(engine.totalSelectedBytes == 0 || engine.isScanning)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.40))
                .background(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(AuraTheme.glassBorder, lineWidth: 0.5)
        )
    }

    private var headerDescription: String {
        switch engine.selectedCategory {
        case .smartClean:
            return "Residuos y cachés recreables de forma segura (Impacto cero en el sistema)."
        case .externalOffload:
            return "Modelos IA, descargas y proyectos pesados listos para offload con symlinks."
        case .userCaches:
            return "Cachés de navegación web, actualizadores y librerías temporales."
        case .developerResiduals:
            return "Artefactos de Xcode, Gradle, uv, npm y simuladores de desarrollo."
        case .applicationSupport:
            return "Datos maestros de aplicaciones. Requiere confirmación y cautela."
        case .trashAndDownloads:
            return "Archivos en Papelera y carpetas de descargas acumuladas."
        case .none:
            return "Análisis unificado de almacenamiento APFS."
        }
    }

    private func executeOperation() {
        Task {
            switch currentOperation {
            case .clean(let mode):
                let report = await engine.deleteSelectedItems(mode: mode) { _, _ in }
                self.resultAlertMessage = "Se eliminaron \(report.deletedItemsCount) elementos liberando \(report.formattedFreedBytes) en tu disco principal."
                self.showResultAlert = true

            case .offload(let volume):
                let report = await engine.offloadSelectedItems(to: volume) { _, _ in }
                self.resultAlertMessage = "Se migraron \(report.transferredCount) elementos a '\(volume.name)', liberando \(report.formattedFreedBytes) en tu disco interno con enlaces simbólicos transparentes."
                self.showResultAlert = true
            }
        }
    }
}
