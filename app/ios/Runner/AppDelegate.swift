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
      errorQueue.append(error)
    }
  }
  
    
    func reportWarning(_ message: String) {
        NSLog("🟡 SWIFT WARNING: \(message)")
        os_log("🟡 SWIFT WARNING: %@", log: OSLog.default, type: .default, message)
        // Warnings go to console only - not Sentry to avoid flooding
    }
    
    func flushErrorQueue() -> Int {
        
        // Only flush if Sentry is actually ready
        if SentrySDK.isEnabled {
            let errorCount = errorQueue.count
            
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
            return errorCount
        } else {
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
    
    // Wrap the entire operation in a try-catch to capture any native exceptions
    do {
             // Check if Google Sign-In is properly configured
             guard let configuration = GIDSignIn.sharedInstance.configuration else {
               let error = "Google Sign-In configuration missing - GIDClientID not found"
               
               // Create a simple error - code is mandatory for NSError
               let nsError = NSError(domain: "ConfigurationError", code: -1001, userInfo: [
                 NSLocalizedDescriptionKey: error
               ])
        
        // Use the generic reportError function with the actual error
        reportError(nsError, context: "Google Sign-In configuration check")
        
        completion(false, error)
        return
      }
      
      
      // This is where the native exception would be thrown
      // We need to catch it at the native level
      GIDSignIn.sharedInstance.signIn(withPresenting: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { result, error in
        if let error = error {
          
          // Convert to NSError to get domain and code
          let nsError = error as NSError
          
          // Report the actual Google SDK error with full context
          self.reportError(error, context: "Google Sign-In authentication")
          completion(false, error.localizedDescription)
        } else if let result = result {
          completion(true, nil)
        } else {
          completion(false, "User cancelled")
        }
      }
      
    } catch {
      
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
    
    let result = SentrySDK.capture(exception: exception)
    
    // Check if Sentry has any pending events (simplified check)
  } else {
  }
  }

  // Set up signal handler for SIGABRT and other signals
  signal(SIGABRT) { signal in
    
    // Check if Sentry is initialized before trying to capture
    if SentrySDK.isEnabled {
      SentrySDK.capture(message: "Native signal crash: SIGABRT")
    } else {
    }
    exit(1)
  }

  signal(SIGSEGV) { signal in
    
    // Check if Sentry is initialized before trying to capture
    if SentrySDK.isEnabled {
      SentrySDK.capture(message: "Native signal crash: SIGSEGV")
    } else {
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
    // Set up crash handlers IMMEDIATELY for better observability
    setupCrashHandlers()
    
    
    // Test Sentry immediately to verify it's working
    if SentrySDK.isEnabled {
      SentrySDK.capture(message: "Test message from AppDelegate startup")
    } else {
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
                    let flushedCount = self?.flushErrorQueue() ?? 0
                    result(["success": true, "count": flushedCount])
                case "getQueueStatus":
                    result(["count": self?.errorQueue.count ?? 0])
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
    }
    
    
    
    // Add crash protection
    do {
      GeneratedPluginRegistrant.register(with: self)
    } catch {
      reportError(error, context: "GeneratedPluginRegistrant.register")
    }
    
      do {
        // Check if GoogleService-Info 2.plist exists
        if let path = Bundle.main.path(forResource: "GoogleService-Info 2", ofType: "plist") {
          
          if let plist = NSDictionary(contentsOfFile: path) {
            
            if let clientId = plist["CLIENT_ID"] as? String, !clientId.isEmpty {
              
              // Configure Google Sign-In with crash protection
              GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
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
    
    return urlResult
  }
}