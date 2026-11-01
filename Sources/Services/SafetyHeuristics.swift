import Foundation

public struct SafetyEvaluation: Sendable {
    public let riskLevel: RiskLevel
    public let impactDescription: String
    public let isOffloadable: Bool
    public let isSystemProtected: Bool
    public let protectionReason: String?
    public let suggestedAction: ItemAction

    public init(
        riskLevel: RiskLevel,
        impactDescription: String,
        isOffloadable: Bool = false,
        isSystemProtected: Bool = false,
        protectionReason: String? = nil,
        suggestedAction: ItemAction = .clean
    ) {
        self.riskLevel = riskLevel
        self.impactDescription = impactDescription
        self.isOffloadable = isOffloadable
        self.isSystemProtected = isSystemProtected
        self.protectionReason = protectionReason
        self.suggestedAction = suggestedAction
    }
}

public struct SafetyHeuristics: Sendable {
    public static func evaluate(url: URL, category: ScanCategory, size: Int64) -> SafetyEvaluation {
        let path = url.path

        // MARK: - 1. REGLA DE ORO: PROTECCIÓN ABSOLUTA DE FOTOTECA APPLE
        if path.contains(".photoslibrary") || path.contains("Photos Library") || path.contains("Photo Booth Library") {
            return SafetyEvaluation(
                riskLevel: .critical,
                impactDescription: "Fototeca del sistema macOS. Bloqueada para proteger sincronización con iCloud Photos y la base de datos de PhotoKit.",
                isOffloadable: false,
                isSystemProtected: true,
                protectionReason: "⚠️ Protegido por macOS: Trasladar la fototeca o enlazarse con symlink puede provocar errores de permisos, desconexión de iCloud y fallo al abrir Fotos.",
                suggestedAction: .keep
            )
        }

        // MARK: - 2. CANDIDATOS DE MIGRACIÓN INTELIGENTE A DISCO EXTERNO
        if path.contains("OptGuideOnDeviceModel") {
            return SafetyEvaluation(
                riskLevel: .offload,
                impactDescription: "Modelo de Inteligencia Artificial on-device (~4.0 GB). Se migra a la carpeta de IA del disco externo con symlink transparente.",
                isOffloadable: true,
                isSystemProtected: false,
                suggestedAction: .offload
            )
        }

        if path.contains("nxnative") {
            return SafetyEvaluation(
                riskLevel: .offload,
                impactDescription: "Shaders, texturas y datos de emulación de Nintendo Switch. Se migran a /Volumes/Externo/Games manteniendo funcionalidad íntegra.",
                isOffloadable: true,
                isSystemProtected: false,
                suggestedAction: .offload
            )
        }

        if path.contains("CacheClip") || path.contains("omni_video") {
            return SafetyEvaluation(
                riskLevel: .offload,
                impactDescription: "Clips de renderizado y proyectos de DaVinci Resolve. Almacenamiento idóneo en disco externo de alta velocidad.",
                isOffloadable: true,
                isSystemProtected: false,
                suggestedAction: .offload
            )
        }

        if path.contains("/Downloads") {
            return SafetyEvaluation(
                riskLevel: .offload,
                impactDescription: "Archivos descargados (instaladores .dmg, videos, documentos). Se recomienda transferir al disco externo para respaldar sin saturar el SSD principal.",
                isOffloadable: true,
                isSystemProtected: false,
                suggestedAction: .offload
            )
        }

        // MARK: - 3. CANDIDATOS DE BORRADO SEGURO
        if path.contains("/.npm/_npx") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Caché temporal de paquetes npx ejecutados. Se puede borrar de forma totalmente segura.",
                suggestedAction: .clean
            )
        }

        if path.contains("/Library/Caches") || path.contains("/.cache") || path.contains("/.npm") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Caché temporal de ejecución. Las aplicaciones la recrearán automáticamente. Impacto nulo en el sistema.",
                suggestedAction: .clean
            )
        }

        if path.contains("/Logs") || path.contains("/private/var/log") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Registros de depuración antiguos. Seguro de eliminar; no afecta el funcionamiento del sistema.",
                suggestedAction: .clean
            )
        }

        if path.contains("/.Trash") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Archivos enviados a la papelera por el usuario. Eliminación segura.",
                suggestedAction: .clean
            )
        }

        if path.contains("/DerivedData") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Caché de construcción de Xcode. Se reconstruirá en la próxima compilación del proyecto.",
                suggestedAction: .clean
            )
        }

        if path.contains("/.gradle/caches") || path.contains("/.cache/uv") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Cachés de herramientas de desarrollo (Gradle / uv). Se descargan bajo demanda.",
                suggestedAction: .clean
            )
        }

        if path.contains("/GoogleUpdater/crx_cache") || path.contains("notion-updater") || path.contains("curseforge-updater") {
            return SafetyEvaluation(
                riskLevel: .safe,
                impactDescription: "Descargas obsoletas de actualizadores de aplicaciones.",
                suggestedAction: .clean
            )
        }

        // MARK: - 4. PRECAUCIÓN Y CRÍTICOS
        if path.contains("/Library/Group Containers") && path.contains("whatsapp") {
            return SafetyEvaluation(
                riskLevel: .moderate,
                impactDescription: "Archivos multimedia descargados localmente por WhatsApp.",
                suggestedAction: .clean
            )
        }

        if path.contains("/Library/Application Support") || path.contains("/Library/Containers") || path.contains("/Library/Preferences") {
            return SafetyEvaluation(
                riskLevel: .critical,
                impactDescription: "Configuración o bases de datos maestras de aplicaciones. Requiere precaución.",
                isSystemProtected: true,
                protectionReason: "Puede reiniciar configuraciones activas de la aplicación.",
                suggestedAction: .keep
            )
        }

        return SafetyEvaluation(
            riskLevel: .moderate,
            impactDescription: "Elemento del sistema que puede contener datos de sesión o recursos auxiliares.",
            suggestedAction: .clean
        )
    }
}
