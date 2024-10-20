import UIKit
import Flutter
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var currentLocale: Locale = Locale(identifier: "en-US")

    // Method channel
    private var voiceOverlayChannel: FlutterMethodChannel!

    // Event channels
    private var voiceEventChannel: FlutterEventChannel!
    private var reconciliationStatusChannel: FlutterEventChannel!

    // Event sinks
    public var voiceEventSink: FlutterEventSink?
    public var statusEventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // Method Channel to control recognition
        voiceOverlayChannel = FlutterMethodChannel(name: "com.example.voice_overlay", binaryMessenger: controller.binaryMessenger)
        voiceOverlayChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "initVoiceOverlay":
                self?.initVoiceOverlay(result: result)
            case "startVoiceOverlay":
                let args = call.arguments as? [String: Any]
                let locale = args?["locale"] as? String ?? "en-US"
                self?.requestPermissions { granted in
                    if granted {
                        self?.startVoiceRecognition(result: result, locale: locale)
                    } else {
                        result(FlutterError(code: "PERMISSION_DENIED", message: "Permission denied", details: nil))
                    }
                }
            case "setVoiceOverlayLanguage":
                let args = call.arguments as? [String: Any]
                let locale = args?["locale"] as? String ?? "en-US"
                self?.setVoiceOverlayLanguage(locale: locale)
            case "stopVoiceOverlay":
                self?.stopVoiceRecognition(result: result)
            case "pauseVoiceOverlay":
                self?.pauseVoiceRecognition(result: result)
            case "resetVoiceOverlay":
                self?.resetVoiceRecognitions()
            case "getAvailableLanguages":
                self?.getAvailableLanguages(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Event Channel for recognition results
        voiceEventChannel = FlutterEventChannel(name: "com.example.voice_overlay_stream", binaryMessenger: controller.binaryMessenger)
        voiceEventChannel.setStreamHandler(WordHandler(appDelegate: self))

        // Event Channel for reconciliation status updates
        reconciliationStatusChannel = FlutterEventChannel(name: "com.example.reconciliation_status_stream", binaryMessenger: controller.binaryMessenger)
        reconciliationStatusChannel.setStreamHandler(StatusHandler(appDelegate: self))

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initVoiceOverlay(result: @escaping FlutterResult) {
        // Set default language to "en-US"
        currentLocale = Locale(identifier: "en-US")
        speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        result("Voice overlay initialized with default language en-US")
    }

    private func startVoiceRecognition(result: @escaping FlutterResult, locale: String) {
        // Use the provided locale or the currentLocale if locale is not provided
        let localeToUse = Locale(identifier: locale)
        speechRecognizer = SFSpeechRecognizer(locale: localeToUse)
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine, let request = request else {
            result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize", details: nil))
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: "AUDIO_ENGINE_ERROR", message: "Failed to start audio engine", details: error.localizedDescription))
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                // Send recognition result to Flutter
                self.voiceEventSink?(recognizedText)
            }

            if let error = error {
                // Send recognition error and update status
                self.voiceEventSink?(FlutterError(code: "RECOGNITION_ERROR", message: error.localizedDescription, details: nil))
                self.statusEventSink?(StatusEnum.error.rawValue)
                self.stopVoiceRecognitions()
            }
        })

        result("Recognition started")
        // Send status update to Flutter
        self.statusEventSink?(StatusEnum.started.rawValue)
    }

    private func setVoiceOverlayLanguage(locale: String) {
        currentLocale = Locale(identifier: locale)
        speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
    }
        private func stopVoiceRecognition(result: @escaping FlutterResult) {
            stopVoiceRecognitions()
            result("Recognition stopped")
            // Send status update to Flutter
            self.statusEventSink?(StatusEnum.stopped.rawValue)
        }
    
        private func pauseVoiceRecognition(result: @escaping FlutterResult) {
            audioEngine?.pause()
            result("Recognition paused")
            // Send status update to Flutter
            self.statusEventSink?(StatusEnum.paused.rawValue)
        }
    
        private func stopVoiceRecognitions() {
            audioEngine?.stop()
            request?.endAudio()
        }
    
        private func resetVoiceRecognitions() {
            stopVoiceRecognitions()
            recognitionTask?.cancel()
            recognitionTask = nil
            self.statusEventSink?(StatusEnum.reset.rawValue)
        }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        let speechRecognitionAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted

        if speechRecognitionAuthorized && microphoneAuthorized {
            completion(true)
        } else {
            SFSpeechRecognizer.requestAuthorization { status in
                let speechAuthorized = status == .authorized
                AVAudioSession.sharedInstance().requestRecordPermission { microphoneAuthorized in
                    completion(speechAuthorized && microphoneAuthorized)
                }
            }
        }
    }

    private func getAvailableLanguages(result: @escaping FlutterResult) {
        let availableLocales = SFSpeechRecognizer.supportedLocales()
        let languageCodes = availableLocales.map { $0.identifier }
        result(languageCodes)
    }
}

enum StatusEnum: String {
    case started = "Started"
    case stopped = "Stopped"
    case reset = "Reset"
    case paused = "Paused"
    case error = "Error"
}

class WordHandler: NSObject, FlutterStreamHandler {
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        appDelegate?.voiceEventSink = eventSink
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        appDelegate?.voiceEventSink = nil
        return nil
    }
}

class StatusHandler: NSObject, FlutterStreamHandler {
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        appDelegate?.statusEventSink = eventSink
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        appDelegate?.statusEventSink = nil
        return nil
    }
}
