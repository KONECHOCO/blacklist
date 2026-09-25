import CallKit
import Flutter
import UIKit

/// Flutter <-> iOS bridge ("com.konechoco.blacklist/screening").
/// iOS cannot inspect calls live: the app hands CallKit a list (Call Directory
/// extension) of numbers to block and numbers to label as spam.
final class ScreeningBridge {
    static let group = "group.com.konechoco.blacklist"
    static let extensionId = "com.konechoco.blacklist.CallDirectory"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "com.konechoco.blacklist/screening", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "platform":
                result("ios")
            case "isActive":
                CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionId) { status, _ in
                    DispatchQueue.main.async { result(status == .enabled) }
                }
            case "requestRole":
                // iOS has no permission prompt: the user switches the extension on in Settings.
                if #available(iOS 13.4, *) {
                    CXCallDirectoryManager.sharedInstance.openSettings { _ in DispatchQueue.main.async { result(false) } }
                } else {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    result(false)
                }
            case "writeCallDirectory":
                guard let args = call.arguments as? [String: String],
                      let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
                    result(FlutterError(code: "no-group", message: "App Group not available", details: nil))
                    return
                }
                do {
                    try (args["block"] ?? "").write(to: dir.appendingPathComponent("block.txt"), atomically: true, encoding: .utf8)
                    try (args["identify"] ?? "").write(to: dir.appendingPathComponent("identify.txt"), atomically: true, encoding: .utf8)
                } catch {
                    result(FlutterError(code: "write", message: error.localizedDescription, details: nil))
                    return
                }
                CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionId) { error in
                    DispatchQueue.main.async { result(error == nil ? true : error!.localizedDescription) }
                }
            case "readLog", "takeLaunchNumber":
                result(nil)  // iOS apps can't read call history
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
