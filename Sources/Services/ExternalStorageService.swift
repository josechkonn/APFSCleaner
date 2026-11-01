import Foundation

public struct ExternalVolume: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let fileSystemType: String

    public var formattedFreeSpace: String {
        ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
    }

    public var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

public enum OffloadError: LocalizedError, Sendable {
    case noExternalDriveFound
    case volumeNotMounted(String)
    case systemProtected(String)
    case transferFailed(String)
    case symlinkFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noExternalDriveFound:
            return "No se detectó ningún disco externo APFS conectado en /Volumes."
        case .volumeNotMounted(let path):
            return "El volumen externo en '\(path)' no está montado actualmente."
        case .systemProtected(let reason):
            return "Operación rechazada por seguridad: \(reason)"
        case .transferFailed(let details):
            return "Error al transferir archivos al disco externo: \(details)"
        case .symlinkFailed(let details):
            return "Error al crear el enlace simbólico tras la migración: \(details)"
        }
    }
}

public struct OffloadReport: Sendable {
    public var transferredCount: Int = 0
    public var freedBytes: Int64 = 0
    public var errors: [String] = []

    public var formattedFreedBytes: String {
        ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }
}

public actor ExternalStorageService {
    private let fileManager = FileManager.default

    public init() {}

    public func detectExternalVolumes() -> [ExternalVolume] {
        guard let volumeURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [
                .volumeIsRemovableKey,
                .volumeIsInternalKey,
                .volumeLocalizedNameKey,
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey,
                .volumeTypeNameKey
            ],
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }

        var results: [ExternalVolume] = []

        for url in volumeURLs {
            let path = url.path
            // Omitir disco raíz y volúmenes especiales
            if path == "/" || path.contains("Recovery") || path.contains("VM") || path.contains("Preboot") || path.contains("Update") {
                continue
            }

            let vals = try? url.resourceValues(forKeys: [
                .volumeIsInternalKey,
                .volumeLocalizedNameKey,
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey,
                .volumeTypeNameKey
            ])

            let isInternal = vals?.volumeIsInternal ?? false
            let name = vals?.volumeLocalizedName ?? url.lastPathComponent
            let free = Int64(vals?.volumeAvailableCapacity ?? 0)
            let total = Int64(vals?.volumeTotalCapacity ?? 0)
            let fsType = vals?.volumeTypeName ?? "APFS"

            // Si está en /Volumes y no es el raíz, es un disco secundario/externo
            if !isInternal || url.path.hasPrefix("/Volumes/") {
                results.append(ExternalVolume(
                    id: url.path,
                    name: name,
                    url: url,
                    totalBytes: total,
                    freeBytes: free,
                    fileSystemType: fsType
                ))
            }
        }

        return results
    }

    public func offloadItem(
        _ item: FileItem,
        to volume: ExternalVolume
    ) async throws -> Int64 {
        // Validación de protección estricta
        if item.isSystemProtected {
            throw OffloadError.systemProtected(item.protectionReason ?? "Este elemento está protegido por macOS.")
        }

        let sourceURL = item.url
        let sourcePath = sourceURL.path

        guard fileManager.fileExists(atPath: sourcePath) else {
            return 0
        }

        // Determinar destino inteligente
        let destinationURL = destinationURLFor(item: item, in: volume)
        let destinationParent = destinationURL.deletingLastPathComponent()

        try fileManager.createDirectory(at: destinationParent, withIntermediateDirectories: true)

        // Transferencia mediante rsync con preservación de atributos POSIX
        let rsyncProcess = Process()
        rsyncProcess.executableURL = URL(fileURLWithPath: "/usr/bin/rsync")
        
        let isDir = (try? sourceURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        let sourceArg = isDir ? "\(sourcePath)/" : sourcePath
        let destArg = isDir ? "\(destinationURL.path)/" : destinationURL.path

        if isDir {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }

        rsyncProcess.arguments = ["-av", "--safe-links", sourceArg, destArg]

        let pipe = Pipe()
        rsyncProcess.standardError = pipe
        try rsyncProcess.run()
        rsyncProcess.waitUntilExit()

        guard rsyncProcess.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errorData, encoding: .utf8) ?? "Error de proceso"
            throw OffloadError.transferFailed(errStr)
        }

        // Si la copia fue exitosa, remover el original y crear symlink
        try fileManager.removeItem(at: sourceURL)
        
        do {
            try fileManager.createSymbolicLink(atPath: sourcePath, withDestinationPath: destinationURL.path)
        } catch {
            throw OffloadError.symlinkFailed("Se transfirieron los datos pero falló el symlink: \(error.localizedDescription)")
        }

        return item.sizeInBytes
    }

    private func destinationURLFor(item: FileItem, in volume: ExternalVolume) -> URL {
        let name = item.name
        let path = item.path

        if path.contains("OptGuideOnDeviceModel") {
            return volume.url.appendingPathComponent("IA/Chrome_OptGuideOnDeviceModel", isDirectory: true)
        }

        if path.contains("Library/Application Support/nxnative") {
            return volume.url.appendingPathComponent("Games/nxnative_data", isDirectory: true)
        }

        if path.hasSuffix("/nxnative") {
            return volume.url.appendingPathComponent("Proyectos/nxnative", isDirectory: true)
        }

        if path.contains("CacheClip") {
            return volume.url.appendingPathComponent("Davinci/CacheClip", isDirectory: true)
        }

        if path.contains("Downloads") {
            return volume.url.appendingPathComponent("Downloads/\(name)", isDirectory: false)
        }

        return volume.url.appendingPathComponent("Offload/\(item.category.rawValue)/\(name)", isDirectory: true)
    }
}
