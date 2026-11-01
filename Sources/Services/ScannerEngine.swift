import Foundation
import Observation

@Observable
@MainActor
public final class ScannerEngine {
    public var isScanning: Bool = false
    public var currentScanningPath: String = ""
    public var scannedCount: Int = 0
    public var items: [FileItem] = []
    public var selectedCategory: ScanCategory? = .smartClean
    public var selectedRiskFilter: RiskLevel? = nil

    public var externalVolumes: [ExternalVolume] = []
    public var selectedExternalVolume: ExternalVolume? = nil

    private let apfsCalculator = APFSCalculator()
    private let externalService = ExternalStorageService()
    private let fileManager = FileManager.default

    public init() {
        refreshExternalVolumes()
    }

    public var totalSelectedBytes: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var totalBytesFound: Int64 {
        items.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var totalOffloadableBytes: Int64 {
        items.filter { $0.isOffloadable }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var totalSafeCleanBytes: Int64 {
        items.filter { $0.riskLevel == .safe }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var filteredItems: [FileItem] {
        items.filter { item in
            let matchesCategory: Bool
            if let selectedCategory = selectedCategory {
                if selectedCategory == .smartClean {
                    matchesCategory = item.riskLevel == .safe
                } else if selectedCategory == .externalOffload {
                    matchesCategory = item.isOffloadable
                } else {
                    matchesCategory = item.category == selectedCategory
                }
            } else {
                matchesCategory = true
            }

            let matchesRisk = selectedRiskFilter == nil || item.riskLevel == selectedRiskFilter
            return matchesCategory && matchesRisk
        }
        .sorted { $0.sizeInBytes > $1.sizeInBytes }
    }

    public func refreshExternalVolumes() {
        Task {
            let volumes = await externalService.detectExternalVolumes()
            self.externalVolumes = volumes
            if self.selectedExternalVolume == nil || !volumes.contains(where: { $0.id == self.selectedExternalVolume?.id }) {
                self.selectedExternalVolume = volumes.first
            }
        }
    }

    public func startFullScan() async {
        guard !isScanning else { return }

        isScanning = true
        scannedCount = 0
        currentScanningPath = "Analizando volumen APFS..."
        items.removeAll(keepingCapacity: true)

        refreshExternalVolumes()

        let categories = ScanCategory.allCases
        var aggregatedItems: [FileItem] = []

        await withTaskGroup(of: [FileItem].self) { group in
            for category in categories {
                group.addTask { [calculator = self.apfsCalculator] in
                    return await Self.scanCategoryDirectories(category, calculator: calculator)
                }
            }

            for await categoryResults in group {
                aggregatedItems.append(contentsOf: categoryResults)
                self.scannedCount += categoryResults.count
            }
        }

        // Deduplicar por URL
        var seenURLs = Set<URL>()
        var uniqueItems: [FileItem] = []
        for item in aggregatedItems {
            if !seenURLs.contains(item.url) {
                seenURLs.insert(item.url)
                uniqueItems.append(item)
            }
        }

        self.items = uniqueItems
        self.isScanning = false
        self.currentScanningPath = "Listo. \(uniqueItems.count) elementos analizados con éxito."
    }

    private nonisolated static func scanCategoryDirectories(
        _ category: ScanCategory,
        calculator: APFSCalculator
    ) async -> [FileItem] {
        let fm = FileManager.default
        var results: [FileItem] = []

        for rootDirectory in category.targetDirectories {
            guard fm.fileExists(atPath: rootDirectory.path) else { continue }

            // Si el directorio objetivo es en sí un elemento específico (ej: OptGuideOnDeviceModel o DerivedData)
            let isTargetDirectBundle = rootDirectory.path.contains("OptGuideOnDeviceModel") ||
                                      rootDirectory.path.hasSuffix("/DerivedData") ||
                                      rootDirectory.path.hasSuffix("/.npm/_npx")

            if isTargetDirectBundle {
                let size = calculator.allocatedSize(of: rootDirectory)
                if size > 1024 * 1024 { // Mayor a 1 MB
                    let eval = SafetyHeuristics.evaluate(url: rootDirectory, category: category, size: size)
                    let modDate = (try? rootDirectory.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                    let item = FileItem(
                        url: rootDirectory,
                        name: rootDirectory.lastPathComponent,
                        path: rootDirectory.path,
                        sizeInBytes: size,
                        riskLevel: eval.riskLevel,
                        impactDescription: eval.impactDescription,
                        category: category,
                        lastModified: modDate,
                        isSelected: eval.riskLevel == .safe || eval.isOffloadable,
                        isOffloadable: eval.isOffloadable,
                        isSystemProtected: eval.isSystemProtected,
                        protectionReason: eval.protectionReason,
                        suggestedAction: eval.suggestedAction
                    )
                    results.append(item)
                }
                continue
            }

            do {
                let contents = try fm.contentsOfDirectory(
                    at: rootDirectory,
                    includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                for itemURL in contents {
                    let itemName = itemURL.lastPathComponent
                    let itemPath = itemURL.path

                    // Omitir symlinks ya existentes para evitar re-escaneo
                    let isSymlink = (try? itemURL.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink ?? false
                    if isSymlink { continue }

                    let size = calculator.allocatedSize(of: itemURL)
                    guard size > 1024 * 1024 else { continue } // Mínimo 1 MB para evitar ruido

                    let modDate = (try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                    let eval = SafetyHeuristics.evaluate(url: itemURL, category: category, size: size)

                    let item = FileItem(
                        url: itemURL,
                        name: itemName,
                        path: itemPath,
                        sizeInBytes: size,
                        riskLevel: eval.riskLevel,
                        impactDescription: eval.impactDescription,
                        category: category,
                        lastModified: modDate,
                        isSelected: eval.riskLevel == .safe,
                        isOffloadable: eval.isOffloadable,
                        isSystemProtected: eval.isSystemProtected,
                        protectionReason: eval.protectionReason,
                        suggestedAction: eval.suggestedAction
                    )
                    results.append(item)
                }
            } catch {
                continue
            }
        }

        return results
    }

    public func toggleSelection(for itemID: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemID }) {
            // No permitir seleccionar elementos con protección de sistema crítica
            if !items[index].isSystemProtected {
                items[index].isSelected.toggle()
            }
        }
    }

    public func selectAllFiltered(onlySafe: Bool = true) {
        let allowedIDs = Set(filteredItems.filter { item in
            if item.isSystemProtected { return false }
            return !onlySafe || item.riskLevel == .safe || item.isOffloadable
        }.map { $0.id })

        for i in 0..<items.count where allowedIDs.contains(items[i].id) {
            items[i].isSelected = true
        }
    }

    public func deselectAllFiltered() {
        let targetIDs = Set(filteredItems.map { $0.id })
        for i in 0..<items.count where targetIDs.contains(items[i].id) {
            items[i].isSelected = false
        }
    }

    public func deleteSelectedItems(
        mode: DeletionMode,
        onProgressUpdate: @escaping @MainActor (_ currentItem: String, _ progress: Double) -> Void
    ) async -> DeletionReport {
        let selectedItems = items.filter { $0.isSelected && !$0.isSystemProtected }
        guard !selectedItems.isEmpty else { return DeletionReport() }

        isScanning = true
        currentScanningPath = "Limpiando \(selectedItems.count) elementos..."

        let service = DeletionService()

        let report = await service.executeDeletion(
            items: selectedItems,
            mode: mode
        ) { currentItem, progressRatio in
            Task { @MainActor in
                self.currentScanningPath = "Limpiando: \(currentItem)"
                onProgressUpdate(currentItem, progressRatio)
            }
        }

        let failedURLs = Set(report.errors.map { $0.itemURL })
        self.items.removeAll { item in
            item.isSelected && !failedURLs.contains(item.url)
        }

        self.isScanning = false
        self.currentScanningPath = "Limpieza completada: \(report.deletedItemsCount) eliminados (\(report.formattedFreedBytes) liberados)."

        return report
    }

    public func offloadSelectedItems(
        to volume: ExternalVolume,
        onProgressUpdate: @escaping @MainActor (_ currentItem: String, _ progress: Double) -> Void
    ) async -> OffloadReport {
        let offloadableItems = items.filter { $0.isSelected && $0.isOffloadable && !$0.isSystemProtected }
        guard !offloadableItems.isEmpty else { return OffloadReport() }

        isScanning = true
        currentScanningPath = "Migrando al disco externo '\(volume.name)'..."

        var report = OffloadReport()
        let total = Double(offloadableItems.count)

        for (index, item) in offloadableItems.enumerated() {
            let ratio = total > 0 ? Double(index + 1) / total : 1.0
            self.currentScanningPath = "Transfiriendo: \(item.name)"
            onProgressUpdate(item.name, ratio)

            do {
                let freed = try await externalService.offloadItem(item, to: volume)
                report.transferredCount += 1
                report.freedBytes += freed

                // Remover de la lista ya que ahora es un symlink
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items.remove(at: idx)
                }
            } catch {
                report.errors.append("\(item.name): \(error.localizedDescription)")
            }
        }

        self.isScanning = false
        self.currentScanningPath = "Migración completada: \(report.transferredCount) elementos transferidos (\(report.formattedFreedBytes) liberados en disco interno)."

        refreshExternalVolumes()
        return report
    }
}
