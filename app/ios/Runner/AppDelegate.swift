import UIKit
import Flutter
import GoogleSignIn
import os.log
import Sentry

// MARK: - Generic Error Reporting
// Sentry's native SDK automatically captures ALL exceptions - no method channels needed!
extension AppDelegate {
  func reportError(_ error: Error, context: String = "") {
    let nsError = error as NSError
    let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
    
    NSLog("🔴 SWIFT ERROR: \(message)")
    os_log("🔴 SWIFT ERROR: %@", log: OSLog.default, type: .error, message)
    
    // Check if Sentry is ready, otherwise queue the error
    if SentrySDK.isEnabled {
      NSLog("🔵 SWIFT DEBUG: Reporting error directly to SentrySDK")
      SentrySDK.capture(error: error) { scope in
        scope.setTag(value: "native_swift", key: "source")
        scope.setTag(value: "ios", key: "platform")
        scope.setContext(value: [
          "domain": nsError.domain,
          "code": nsError.code,
          "thread": "\(Thread.current)",
          "context": context
        ], key: "swift_error")
      }
    } else {
      NSLog("🔵 SWIFT DEBUG: Sentry not ready, queuing error")
      errorQueue.append(error)
    }
  }
  
    
    func reportWarning(_ message: String) {
        NSLog("🟡 SWIFT WARNING: \(message)")
        os_log("🟡 SWIFT WARNING: %@", log: OSLog.default, type: .default, message)
        // Warnings go to console only - not Sentry to avoid flooding
    }
    
    func flushErrorQueue() -> Int {
        NSLog("🔵 SWIFT DEBUG: Flushing \(errorQueue.count) queued errors to Sentry")
        NSLog("🔵 SWIFT DEBUG: Sentry isEnabled: \(SentrySDK.isEnabled)")
        
        // Only flush if Sentry is actually ready
        if SentrySDK.isEnabled {
            let errorCount = errorQueue.count
            NSLog("🔵 SWIFT DEBUG: Sending \(errorCount) queued errors to Sentry...")
            
            // Send each queued error directly to SentrySDK
            for error in errorQueue {
                let nsError = error as NSError
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "native_swift_queued", key: "source")
                    scope.setTag(value: "ios", key: "platform")
                    scope.setContext(value: [
                        "domain": nsError.domain,
                        "code": nsError.code,
                        "thread": "\(Thread.current)",
                        "queued": true
                    ], key: "swift_error")
                }
            }
            errorQueue.removeAll()
            NSLog("🔵 SWIFT DEBUG: Successfully sent \(errorCount) errors to Sentry")
            return errorCount
        } else {
            NSLog("🔵 SWIFT DEBUG: Sentry not ready, keeping \(errorQueue.count) errors in queue")
            return 0
        }
    }
    
    
    func notifyFlutterOfError(_ message: String) {
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("reportError", arguments: ["error": message])
        }
    }
  
  // Safe Google Sign-In wrapper that catches native exceptions
  func safeGoogleSignIn(completion: @escaping (Bool, String?) -> Void) {
    NSLog("🔵 SWIFT DEBUG: Starting safe Google Sign-In...")
    
    // Wrap the entire operation in a try-catch to capture any native exceptions
    do {
             // Check if Google Sign-In is properly configured
             guard let configuration = GIDSignIn.sharedInstance.configuration else {
               let error = "Google Sign-In configuration missing - GIDClientID not found"
               NSLog("🔴 SWIFT ERROR: \(error)")
               
               // Create a simple error - code is mandatory for NSError
               let nsError = NSError(domain: "ConfigurationError", code: -1001, userInfo: [
                 NSLocalizedDescriptionKey: error
               ])
        
        // Use the generic reportError function with the actual error
        reportError(nsError, context: "Google Sign-In configuration check")
        
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
          self.reportError(error, context: "Google Sign-In authentication")
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
      reportError(error, context: "safeGoogleSignIn exception")
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
  private var errorQueue: [Error] = []
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Don't initialize Sentry in Swift - let Flutter handle it
    // Swift will queue errors until Flutter initializes Sentry
    NSLog("🔵 SWIFT DEBUG: Skipping Sentry initialization in Swift - will queue errors until Flutter is ready")
    
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
    
    // Set up method channels for safe Google Sign-In and error queue flushing
    if let controller = window?.rootViewController as? FlutterViewController {
      // Set up method channel for safe Google Sign-In
      let safeGoogleSignInChannel = FlutterMethodChannel(name: "safe_google_sign_in", binaryMessenger: controller.binaryMessenger)
      
      // Set up method channel for error queue flushing
      let errorQueueChannel = FlutterMethodChannel(name: "error_queue", binaryMessenger: controller.binaryMessenger)
      
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
      
            errorQueueChannel.setMethodCallHandler { [weak self] (call, result) in
                switch call.method {
                case "flushQueue":
                    NSLog("🔵 SWIFT DEBUG: Received flushQueue call from Flutter")
                    let flushedCount = self?.flushErrorQueue() ?? 0
                    result(["success": true, "count": flushedCount])
                case "getQueueStatus":
                    NSLog("🔵 SWIFT DEBUG: Received getQueueStatus call from Flutter")
                    result(["count": self?.errorQueue.count ?? 0])
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
      reportError(error, context: "GeneratedPluginRegistrant.register")
    }
    
      // Add crash protection around Google Sign-In
      NSLog("🔵 SWIFT DEBUG: Starting Google Sign-In configuration with crash protection...")
      
      do {
        // Check if GoogleService-Info 2.plist exists
        if let path = Bundle.main.path(forResource: "GoogleService-Info 2", ofType: "plist") {
          NSLog("🔵 SWIFT DEBUG: GoogleService-Info.plist found at: \(path)")
          
          if let plist = NSDictionary(contentsOfFile: path) {
            NSLog("🔵 SWIFT DEBUG: Successfully loaded plist")
            
            if let clientId = plist["CLIENT_ID"] as? String, !clientId.isEmpty {
              NSLog("🔵 SWIFT DEBUG: CLIENT_ID found: \(String(clientId.prefix(10)))...")
              
              // Configure Google Sign-In with crash protection
              GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
              NSLog("🔵 SWIFT DEBUG: GoogleSignIn configured successfully!")
            } else {
              let error = NSError(domain: "ConfigurationError", code: -1002, userInfo: [
                NSLocalizedDescriptionKey: "CLIENT_ID not found or empty"
              ])
              reportError(error, context: "Google Sign-In configuration")
            }
          } else {
            let error = NSError(domain: "ConfigurationError", code: -1003, userInfo: [
              NSLocalizedDescriptionKey: "Failed to read GoogleService-Info.plist"
            ])
            reportError(error, context: "Google Sign-In configuration")
          }
        } else {
          let error = NSError(domain: "ConfigurationError", code: -1004, userInfo: [
            NSLocalizedDescriptionKey: "GoogleService-Info 2.plist not found in app bundle"
          ])
          reportError(error, context: "Google Sign-In configuration")
          // Notify Flutter about the error
          notifyFlutterOfError("Google Sign-In is not configured. Please contact support.")
          // Don't configure Google Sign-In if plist is missing - this prevents the hang
          NSLog("🔵 SWIFT DEBUG: Skipping Google Sign-In configuration due to missing plist")
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
      } catch {
        reportError(error, context: "Google Sign-In configuration")
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
      let error = NSError(domain: "TimeoutError", code: -2001, userInfo: [
        NSLocalizedDescriptionKey: "URL handling timed out for: \(url.absoluteString)"
      ])
      reportError(error, context: "Google Sign-In URL handling")
      return false
    }
    
    NSLog("🔵 SWIFT DEBUG: URL handling result: \(urlResult ? "success" : "failed")")
    return urlResult
  }
}