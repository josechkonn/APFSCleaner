import Foundation
import AppKit
import Observation

public enum PermissionStatus: Sendable {
    case granted
    case denied
    case unknown
}

@Observable
@MainActor
public final class FullDiskAccessManager {
    public static let shared = FullDiskAccessManager()
    
    public var status: PermissionStatus = .unknown
    
    public init() {
        checkPermission()
    }

    @discardableResult
    public func checkPermission() -> PermissionStatus {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        
        let testPaths = [
            home.appendingPathComponent("Library/Safari/CloudTabs.db").path,
            home.appendingPathComponent("Library/Safari/Bookmarks.plist").path,
            home.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db").path
        ]
        
        var hasAccess = false
        for path in testPaths {
            if fileManager.isReadableFile(atPath: path) {
                hasAccess = true
                break
            }
            if let fileHandle = FileHandle(forReadingAtPath: path) {
                try? fileHandle.close()
                hasAccess = true
                break
            }
        }
        
        self.status = hasAccess ? .granted : .denied
        return self.status
    }

    public func openSystemSettingsPrivacy() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
