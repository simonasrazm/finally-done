import Flutter
import Speech
import AVFoundation

class SpeechRecognitionPlugin: NSObject, FlutterPlugin {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var result: FlutterResult?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "speech_recognition", binaryMessenger: registrar.messenger())
        let instance = SpeechRecognitionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            guard let args = call.arguments as? [String: Any],
                  let language = args["language"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Language not provided", details: nil))
                return
            }
            startRecording(language: language, result: result)
            
        case "stopRecording":
            stopRecording()
            result(nil)
            
        case "isAvailable":
            guard let args = call.arguments as? [String: Any],
                  let language = args["language"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Language not provided", details: nil))
                return
            }
            isAvailable(language: language, result: result)
            
        case "requestPermission":
            requestPermission(result: result)
            
        case "getSupportedLanguages":
            getSupportedLanguages(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startRecording(language: String, result: @escaping FlutterResult) {
        self.result = result
        
        // Request permissions
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.startRecognition(language: language)
                case .denied:
                    result(FlutterError(code: "PERMISSION_DENIED", 
                                      message: "Speech recognition permission denied",
                                      details: nil))
                case .restricted:
                    result(FlutterError(code: "PERMISSION_RESTRICTED",
                                      message: "Speech recognition restricted on this device",
                                      details: nil))
                case .notDetermined:
                    result(FlutterError(code: "PERMISSION_NOT_DETERMINED",
                                      message: "Speech recognition permission not determined",
                                      details: nil))
                @unknown default:
                    result(FlutterError(code: "UNKNOWN_ERROR",
                                      message: "Unknown authorization status",
                                      details: nil))
                }
            }
        }
    }
    
    private func startRecognition(language: String) {
        guard let result = self.result else { return }
        
        // Cancel any ongoing recognition
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Create speech recognizer for the specified language
        let locale = Locale(identifier: language)
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            result(FlutterError(code: "RECOGNIZER_NOT_AVAILABLE",
                              message: "Speech recognizer not available for language: \(language)",
                              details: nil))
            return
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            result(FlutterError(code: "AUDIO_SESSION_ERROR",
                              message: "Failed to configure audio session: \(error.localizedDescription)",
                              details: nil))
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            result(FlutterError(code: "REQUEST_ERROR",
                              message: "Unable to create recognition request",
                              details: nil))
            return
        }
        
        // Configure request for on-device recognition
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Start audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: "AUDIO_ENGINE_ERROR",
                              message: "Failed to start audio engine: \(error.localizedDescription)",
                              details: nil))
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { recognitionResult, error in
            var isFinal = false
            
            if let recognitionResult = recognitionResult {
                let transcription = recognitionResult.bestTranscription.formattedString
                isFinal = recognitionResult.isFinal
                
                // Only return final result
                if isFinal {
                    result(transcription)
                    self.stopRecognition()
                }
            }
            
            if error != nil {
                result(FlutterError(code: "RECOGNITION_ERROR",
                                  message: "Recognition error: \(error!.localizedDescription)",
                                  details: nil))
                self.stopRecognition()
            }
        }
    }
    
    private func stopRecording() {
        stopRecognition()
    }
    
    private func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    private func isAvailable(language: String, result: @escaping FlutterResult) {
        let locale = Locale(identifier: language)
        let recognizer = SFSpeechRecognizer(locale: locale)
        result(recognizer?.isAvailable ?? false)
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    result(3) // SpeechPermissionStatus.authorized
                case .denied:
                    result(1) // SpeechPermissionStatus.denied
                case .restricted:
                    result(2) // SpeechPermissionStatus.restricted
                case .notDetermined:
                    result(0) // SpeechPermissionStatus.notDetermined
                @unknown default:
                    result(0) // SpeechPermissionStatus.notDetermined
                }
            }
        }
    }
    
    private func getSupportedLanguages(result: @escaping FlutterResult) {
        let supportedLanguages = SFSpeechRecognizer.supportedLocales().map { $0.identifier }
        result(supportedLanguages)
    }
}
