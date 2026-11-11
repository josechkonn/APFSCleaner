# APFS Cleaner

Libera espacio en disco en macOS sin miedo a romper nada. Antes de tocar un archivo, la app le asigna un nivel de riesgo, protege lo que pertenece al sistema y pide confirmación antes de borrar.

App nativa en **Swift + SwiftUI**, sin dependencias externas.

## Qué hace

- **Escanea por categorías:**
  - limpieza inteligente;
  - cachés del sistema y de las apps;
  - residuos de desarrollo (DerivedData, Archives, Gradle, uv…);
  - datos de apps y modelos de IA;
  - papelera y descargas.
- **Clasifica cada elemento en 4 niveles de riesgo:**

  | Nivel | Qué significa |
  |---|---|
  | Seguro | Se puede limpiar sin consecuencias (cachés, logs, DerivedData). |
  | Precaución | Conviene revisarlo antes de limpiar. |
  | Migrable a externo | Pesa mucho y se puede mover a otro disco (descargas, modelos de IA, cachés de video). |
  | Protegido por sistema | No se toca (fototecas, Application Support, Containers, Preferences). |

- **Mide el tamaño real en APFS.** Cuenta el espacio asignado en disco, no el tamaño lógico, así que no infla las cifras con clones ni archivos dispersos.
- **Migra a un disco externo.** Detecta los volúmenes conectados en `/Volumes`, mueve allí lo pesado y deja un enlace simbólico en su lugar.
- **Borra con red de seguridad.** Por defecto todo va a la Papelera. El borrado permanente es opcional y siempre se confirma antes, en una hoja de resumen.
- **Acceso total al disco.** Detecta si falta el permiso y abre directamente el panel de Privacidad de Ajustes del Sistema.

## Requisitos

- macOS 14 (Sonoma) o posterior
- Xcode 15+ o la toolchain de Swift 5.9+

## Uso

```bash
git clone https://github.com/josechkonn/APFSCleaner.git
cd APFSCleaner
swift run -c release
```

Para escanear carpetas protegidas, como `~/Library/Containers`, dale a la app **Acceso total al disco** en *Ajustes del Sistema → Privacidad y seguridad*.

También puedes abrir `Package.swift` con Xcode y ejecutar desde ahí.

## Estructura

```
Sources/
├── App/        # Punto de entrada (APFSCleanerApp) y configuración de la ventana
├── Models/     # FileItem, RiskLevel, ScanCategory, modelos de borrado
├── Services/
│   ├── ScannerEngine.swift          # Recorre las carpetas de cada categoría
│   ├── SafetyHeuristics.swift       # Decide el nivel de riesgo de cada ruta
│   ├── APFSCalculator.swift         # Tamaño real asignado en APFS
│   ├── DeletionService.swift        # Papelera o borrado permanente
│   ├── ExternalStorageService.swift # Detección de discos y migración con symlink
│   └── FullDiskAccessManager.swift  # Permiso de acceso total al disco
├── Theme/      # Colores y estilos
└── Views/      # Barra lateral, lista, resumen, hoja de confirmación
Resources/      # Info.plist, icono (.icns) y script que lo genera
```

## Autor

Jose Chacón · [GitHub](https://github.com/josechkonn) · [Portafolio](https://chkon.vercel.app)
