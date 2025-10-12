import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // No Google Sign-In initialization at startup
    // Google services will be initialized only when user tries to connect
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}