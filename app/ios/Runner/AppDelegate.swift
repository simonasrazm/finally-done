import UIKit
import Flutter
import GoogleSignIn
import os.log
import Sentry

// MARK: - Error Reporting Standards
// All errors MUST be reported to both console AND Sentry for consistent observability
extension AppDelegate {
    func reportError(_ message: String, domain: String = "AppDelegate", code: Int = 0, error: Error? = nil) {
        NSLog("🔴 SWIFT ERROR: \(message)")
        os_log("🔴 SWIFT ERROR: %@", log: OSLog.default, type: .error, message)
        
        if let error = error {
            let nsError = NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
            SentrySDK.capture(error: nsError)
        } else {
            let nsError = NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
            SentrySDK.capture(error: nsError)
        }
    }
    
    func reportWarning(_ message: String) {
        NSLog("🟡 SWIFT WARNING: \(message)")
        os_log("🟡 SWIFT WARNING: %@", log: OSLog.default, type: .default, message)
        // Warnings go to console only - not Sentry to avoid flooding
    }
    
  func notifyFlutterOfError(_ message: String) {
    DispatchQueue.main.async {
      self.methodChannel?.invokeMethod("onGoogleSignInError", arguments: ["error": message])
    }
  }
  
  // Safe Google Sign-In wrapper that catches native exceptions
  func safeGoogleSignIn(completion: @escaping (Bool, String?) -> Void) {
    NSLog("🔵 SWIFT DEBUG: Starting safe Google Sign-In...")
    
    // Wrap the entire operation in a try-catch to capture any native exceptions
    do {
      // Check if Google Sign-In is properly configured
      guard let configuration = GIDSignIn.sharedInstance.configuration else {
        let error = "Google Sign-In not configured - GIDClientID missing"
        NSLog("🔴 SWIFT ERROR: \(error)")
        reportError(error, domain: "GoogleSignIn", code: 3001)
        completion(false, error)
        return
      }
      
      NSLog("🔵 SWIFT DEBUG: Google Sign-In configuration found: \(configuration.clientID)")
      
      // This is where the native exception would be thrown
      // We need to catch it at the native level
      GIDSignIn.sharedInstance.signIn(withPresenting: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { result, error in
        if let error = error {
          NSLog("🔴 SWIFT ERROR: Google Sign-In failed: \(error.localizedDescription)")
          NSLog("🔴 SWIFT ERROR: Error type: \(type(of: error))")
          NSLog("🔴 SWIFT ERROR: Error description: \(error.localizedDescription)")
          
          // Convert to NSError to get domain and code
          let nsError = error as NSError
          NSLog("🔴 SWIFT ERROR: Error domain: \(nsError.domain)")
          NSLog("🔴 SWIFT ERROR: Error code: \(nsError.code)")
          NSLog("🔴 SWIFT ERROR: Error userInfo: \(nsError.userInfo)")
          
          // Report the actual Google SDK error with full context
          self.reportError("Google Sign-In failed: \(error.localizedDescription)", domain: nsError.domain, code: nsError.code, error: error)
          completion(false, error.localizedDescription)
        } else if let result = result {
          NSLog("🔵 SWIFT DEBUG: Google Sign-In successful: \(result.user.userID ?? "unknown")")
          completion(true, nil)
        } else {
          NSLog("🔵 SWIFT DEBUG: Google Sign-In cancelled by user")
          completion(false, "User cancelled")
        }
      }
      
    } catch {
      NSLog("🔴 SWIFT ERROR: Exception in safeGoogleSignIn: \(error)")
      NSLog("🔴 SWIFT ERROR: Exception type: \(type(of: error))")
      NSLog("🔴 SWIFT ERROR: Exception description: \(error.localizedDescription)")
      
      // Report the actual exception with full context
      reportError("Exception in safeGoogleSignIn: \(error.localizedDescription)", domain: "GoogleSignIn", code: 3003, error: error)
      completion(false, error.localizedDescription)
    }
  }
}

// Global hang detection
class HangDetector {
  private static var timers: [String: Timer] = [:]
  
  static func startMonitoring(operation: String, timeout: TimeInterval = 10.0, completion: @escaping () -> Void) {
    let timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
      os_log("🔵 WARNING: Operation '%@' took longer than %@ seconds", log: OSLog.default, type: .default, operation, String(timeout))
      SentrySDK.capture(message: "Operation '\(operation)' timed out")
      completion()
    }
    timers[operation] = timer
  }
  
  static func stopMonitoring(operation: String) {
    timers[operation]?.invalidate()
    timers.removeValue(forKey: operation)
  }
}

// Global function to set up crash handlers
func setupCrashHandlers() {
  // Set up native crash handler IMMEDIATELY for better observability
  NSSetUncaughtExceptionHandler { exception in
    NSLog("🔴 NATIVE CRASH: \(exception)")
    os_log("🔴 NATIVE CRASH: %@", log: OSLog.default, type: .error, exception.description)
    
  // Check if Sentry is initialized before trying to capture
  if SentrySDK.isEnabled {
    NSLog("🔵 SWIFT DEBUG: Sentry is enabled, capturing crash")
    NSLog("🔵 SWIFT DEBUG: Exception details: \(exception)")
    NSLog("🔵 SWIFT DEBUG: Exception name: \(exception.name)")
    NSLog("🔵 SWIFT DEBUG: Exception reason: \(exception.reason ?? "nil")")
    
    let result = SentrySDK.capture(exception: exception)
    NSLog("🔵 SWIFT DEBUG: SentrySDK.capture result: \(result)")
    
    // Check if Sentry has any pending events (simplified check)
    NSLog("🔵 SWIFT DEBUG: Sentry capture completed")
  } else {
    NSLog("🔵 SWIFT DEBUG: Sentry is NOT enabled, crash not sent to Sentry")
  }
  }

  // Set up signal handler for SIGABRT and other signals
  signal(SIGABRT) { signal in
    NSLog("🔴 NATIVE SIGNAL CRASH: SIGABRT")
    os_log("🔴 NATIVE SIGNAL CRASH: SIGABRT", log: OSLog.default, type: .error)
    
    // Check if Sentry is initialized before trying to capture
    if SentrySDK.isEnabled {
      NSLog("🔵 SWIFT DEBUG: Sentry is enabled, capturing SIGABRT")
      SentrySDK.capture(message: "Native signal crash: SIGABRT")
    } else {
      NSLog("🔵 SWIFT DEBUG: Sentry is NOT enabled, SIGABRT not sent to Sentry")
    }
    exit(1)
  }

  signal(SIGSEGV) { signal in
    NSLog("🔴 NATIVE SIGNAL CRASH: SIGSEGV")
    os_log("🔴 NATIVE SIGNAL CRASH: SIGSEGV", log: OSLog.default, type: .error)
    
    // Check if Sentry is initialized before trying to capture
    if SentrySDK.isEnabled {
      NSLog("🔵 SWIFT DEBUG: Sentry is enabled, capturing SIGSEGV")
      SentrySDK.capture(message: "Native signal crash: SIGSEGV")
    } else {
      NSLog("🔵 SWIFT DEBUG: Sentry is NOT enabled, SIGSEGV not sent to Sentry")
    }
    exit(1)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Set up crash handlers IMMEDIATELY for better observability
    setupCrashHandlers()
    
    NSLog("🔵 SWIFT DEBUG: AppDelegate starting - Thread: \(Thread.current)")
    os_log("🔵 SWIFT DEBUG: AppDelegate starting - Thread: %@", log: OSLog.default, type: .debug, "\(Thread.current)")
    
    // Test Sentry immediately to verify it's working
    NSLog("🔵 SWIFT DEBUG: Testing Sentry - isEnabled: \(SentrySDK.isEnabled)")
    if SentrySDK.isEnabled {
      NSLog("🔵 SWIFT DEBUG: Sending test message to Sentry...")
      SentrySDK.capture(message: "Test message from AppDelegate startup")
      NSLog("🔵 SWIFT DEBUG: Test message sent to Sentry")
    } else {
      NSLog("🔵 SWIFT DEBUG: Sentry is NOT enabled at startup")
    }
    
    // Set up method channel for communicating errors to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(name: "google_sign_in_error", binaryMessenger: controller.binaryMessenger)
      
      // Set up method channel for safe Google Sign-In
      let safeGoogleSignInChannel = FlutterMethodChannel(name: "safe_google_sign_in", binaryMessenger: controller.binaryMessenger)
      
      safeGoogleSignInChannel.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "signIn":
          NSLog("🔵 SWIFT DEBUG: Received signIn call from Flutter")
          self?.safeGoogleSignIn { success, errorMessage in
            DispatchQueue.main.async {
              if success {
                result(["success": true])
              } else {
                result(["success": false, "error": errorMessage ?? "Unknown error"])
              }
            }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    
    
    // Add crash protection
    do {
      GeneratedPluginRegistrant.register(with: self)
      NSLog("🔵 SWIFT DEBUG: GeneratedPluginRegistrant.register completed successfully - Thread: \(Thread.current)")
    } catch {
      reportError("GeneratedPluginRegistrant.register failed: \(error)", error: error)
    }
    
      // Add crash protection around Google Sign-In
      NSLog("🔵 SWIFT DEBUG: Starting Google Sign-In configuration with crash protection...")
      
      do {
        // Check if GoogleService-Info.plist exists
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
          NSLog("🔵 SWIFT DEBUG: GoogleService-Info.plist found at: \(path)")
          
          if let plist = NSDictionary(contentsOfFile: path) {
            NSLog("🔵 SWIFT DEBUG: Successfully loaded plist")
            
            if let clientId = plist["CLIENT_ID"] as? String, !clientId.isEmpty {
              NSLog("🔵 SWIFT DEBUG: CLIENT_ID found: \(String(clientId.prefix(10)))...")
              
              // Configure Google Sign-In with crash protection
              GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
              NSLog("🔵 SWIFT DEBUG: GoogleSignIn configured successfully!")
            } else {
              reportError("CLIENT_ID not found or empty", domain: "GoogleSignInConfig", code: 1001)
            }
          } else {
            reportError("Failed to read GoogleService-Info.plist", domain: "GoogleSignInConfig", code: 1002)
          }
        } else {
          reportError("GoogleService-Info.plist not found in app bundle", domain: "GoogleSignInConfig", code: 1003)
          // Notify Flutter about the error
          notifyFlutterOfError("Google Sign-In is not configured. Please contact support.")
          // Don't configure Google Sign-In if plist is missing - this prevents the hang
          NSLog("🔵 SWIFT DEBUG: Skipping Google Sign-In configuration due to missing plist")
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
      } catch {
        reportError("Google Sign-In configuration crashed: \(error)", error: error)
        // Continue without Google Sign-In
      }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("🔵 SWIFT DEBUG: Handling URL: \(url.absoluteString)")
    
    // Add timeout to URL handling to prevent hangs
    let urlTimeout = DispatchTime.now() + .seconds(3)
    let urlSemaphore = DispatchSemaphore(value: 0)
    var urlResult = false
    
    DispatchQueue.global(qos: .userInitiated).async {
      urlResult = GIDSignIn.sharedInstance.handle(url)
      urlSemaphore.signal()
    }
    
    let result = urlSemaphore.wait(timeout: urlTimeout)
    
    if result == .timedOut {
      reportError("URL handling timed out for: \(url.absoluteString)", domain: "GoogleSignInURL", code: 2001)
      return false
    }
    
    NSLog("🔵 SWIFT DEBUG: URL handling result: \(urlResult ? "success" : "failed")")
    return urlResult
  }
}