import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "amitabha/ios_backup",
                binaryMessenger: controller.binaryMessenger)
            channel.setMethodCallHandler { call, result in
                guard call.method == "excludeFromBackup" else {
                    result(FlutterMethodNotImplemented)
                    return
                }
                guard
                    let args = call.arguments as? [String: Any],
                    let path = args["path"] as? String
                else {
                    result(FlutterError(code: "bad_args", message: "path is required", details: nil))
                    return
                }
                var url = URL(fileURLWithPath: path)
                do {
                    var values = URLResourceValues()
                    values.isExcludedFromBackup = true
                    try url.setResourceValues(values)
                    result(true)
                } catch {
                    result(FlutterError(
                        code: "set_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
