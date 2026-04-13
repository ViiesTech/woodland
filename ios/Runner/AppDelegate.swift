import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.woodlandseries.app/deep_link"
  private var initialUrl: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Store initial URL if app was opened via deep link
    if let url = launchOptions?[.url] as? URL, url.scheme == "stripe" {
      initialUrl = url.absoluteString
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel after Flutter is initialized
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getInitialLink" {
          result(self?.initialUrl)
          self?.initialUrl = nil // Clear after reading
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle deep links when app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Send deep link to Flutter
    if url.scheme == "stripe" {
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
      }
    }
    return true
  }
  
  // Handle universal links (if needed in future)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      // Handle universal link if needed
      return true
    }
    return false
  }
}
