import Foundation

public enum ScanCategory: String, CaseIterable, Identifiable, Sendable {
    case smartClean = "Limpieza Inteligente"
    case externalOffload = "Migración a Disco Externo"
    case userCaches = "Cachés del Sistema y Apps"
    case developerResiduals = "Entornos de Desarrollo"
    case applicationSupport = "Datos de Apps y Modelos IA"
    case trashAndDownloads = "Papelera y Descargas"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .smartClean: return "sparkles"
        case .externalOffload: return "externaldrive.badge.timemachine"
        case .userCaches: return "cylinder.split.1x2.fill"
        case .developerResiduals: return "hammer.fill"
        case .applicationSupport: return "cpu.fill"
        case .trashAndDownloads: return "trash.fill"
        }
    }

    public var targetDirectories: [URL] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        switch self {
        case .smartClean:
            return [
                home.appendingPathComponent("Library/Caches", isDirectory: true),
                home.appendingPathComponent(".cache", isDirectory: true),
                home.appendingPathComponent(".npm/_npx", isDirectory: true),
                home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true),
                home.appendingPathComponent("Library/Logs", isDirectory: true),
                home.appendingPathComponent(".Trash", isDirectory: true)
            ]

        case .externalOffload:
            return [
                home.appendingPathComponent("Library/Application Support/Google/Chrome/OptGuideOnDeviceModel", isDirectory: true),
                home.appendingPathComponent("Library/Application Support/nxnative", isDirectory: true),
                home.appendingPathComponent("nxnative", isDirectory: true),
                home.appendingPathComponent("Movies/CacheClip", isDirectory: true),
                home.appendingPathComponent("Downloads", isDirectory: true),
                home.appendingPathComponent(".gemini/antigravity/scratch/omni_video", isDirectory: true)
            ]

        case .userCaches:
            return [
                home.appendingPathComponent("Library/Caches", isDirectory: true),
                home.appendingPathComponent(".cache", isDirectory: true),
                home.appendingPathComponent(".npm", isDirectory: true),
                URL(fileURLWithPath: "/Library/Caches", isDirectory: true)
            ]

        case .developerResiduals:
            return [
                home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true),
                home.appendingPathComponent("Library/Developer/Xcode/Archives", isDirectory: true),
                home.appendingPathComponent("Library/Android/sdk/system-images", isDirectory: true),
                home.appendingPathComponent(".android/avd", isDirectory: true),
                home.appendingPathComponent(".expo", isDirectory: true),
                home.appendingPathComponent(".gradle/caches", isDirectory: true),
                home.appendingPathComponent(".cache/uv", isDirectory: true)
            ]

        case .applicationSupport:
            return [
                home.appendingPathComponent("Library/Application Support", isDirectory: true),
                home.appendingPathComponent("Library/Containers", isDirectory: true),
                home.appendingPathComponent("Library/Group Containers", isDirectory: true)
            ]

        case .trashAndDownloads:
            return [
                home.appendingPathComponent(".Trash", isDirectory: true),
                home.appendingPathComponent("Downloads", isDirectory: true)
            ]
        }
    }
}
