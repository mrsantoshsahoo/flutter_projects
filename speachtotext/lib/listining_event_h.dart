
//
//////  new code
//
//import UIKit
//import Flutter
//import Speech
//import AVFoundation
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//    private var speechRecognizer: SFSpeechRecognizer?
//    private var audioEngine: AVAudioEngine?
//    private var request: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private var voiceOverlayChannel: FlutterMethodChannel!
//
//    override func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        let controller = window?.rootViewController as! FlutterViewController
//
//        voiceOverlayChannel = FlutterMethodChannel(name: "com.example.voice_overlay",
//                                                    binaryMessenger: controller.binaryMessenger)
//        voiceOverlayChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
//            switch call.method {
//            case "startVoiceOverlay":
//                self?.requestPermissions { granted in
//                    if granted {
//                        self?.startVoiceRecognition(result: result)
//                    } else {
//                        result(FlutterError(code: "PERMISSION_DENIED",
//                                            message: "Microphone or speech recognition permission denied",
//                                            details: nil))
//                    }
//                }
//            case "stopVoiceOverlay":
//                self?.stopVoiceRecognition(result: result)
//            default:
//                result(FlutterMethodNotImplemented)
//            }
//        }
//
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//
//    private func startVoiceRecognition(result: @escaping FlutterResult) {
//        // Initialize the speech recognizer and audio engine
//        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//        audioEngine = AVAudioEngine()
//        request = SFSpeechAudioBufferRecognitionRequest()
//
//        // Safely unwrap the optional values
//        guard let audioEngine = audioEngine, let request = request else {
//            fatalError("Audio engine or request is unavailable.")
//        }
//
//        // Access the input node from the audio engine
//        let inputNode = audioEngine.inputNode
//
//        // Ensure the input node is available
//        if inputNode == nil {
//            fatalError("Audio engine has no input node.")
//        }
//
//        // Configure the recognition request
//        request.shouldReportPartialResults = true
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            self.request?.append(buffer)
//        }
//
//        // Prepare and start the audio engine
//        audioEngine.prepare()
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Audio engine error: \(error.localizedDescription)")
//            // Handle the error appropriately
//            result(FlutterError(code: "AUDIO_ENGINE_ERROR", message: "Failed to start audio engine", details: error.localizedDescription))
//            return
//        }
//
//        // Start the speech recognition task
//        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
//            if let result = result {
//                let recognizedText = result.bestTranscription.formattedString
//                // Send recognized text to Flutter
//                print("recognizedText \(recognizedText)")
//                self.voiceOverlayChannel.invokeMethod("onVoiceResult", arguments: recognizedText)
//            }
//
//            if let error = error {
//                print("Recognition error: \(error.localizedDescription)")
//                // Send error to Flutter
//                self.voiceOverlayChannel.invokeMethod("onVoiceError", arguments: error.localizedDescription)
//                self.stopVoiceRecognitions() // Ensure recognition is stopped
//            }
//        }
//    }
//
//
//    private func stopVoiceRecognition(result: @escaping FlutterResult) {
//        stopVoiceRecognitions()
//        result(nil)
//    }
//    private func stopVoiceRecognitions() {
//        audioEngine?.stop()
//        request?.endAudio()
//        recognitionTask?.cancel()
//        recognitionTask = nil
//    }
//
//    private func requestPermissions(completion: @escaping (Bool) -> Void) {
//        let speechRecognizer = SFSpeechRecognizer()
//        let speechRecognitionAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
//        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
//
//        if speechRecognitionAuthorized && microphoneAuthorized {
//            completion(true)
//        } else {
//            SFSpeechRecognizer.requestAuthorization { status in
//                let speechAuthorized = status == .authorized
//                AVAudioSession.sharedInstance().requestRecordPermission { microphoneAuthorized in
//                    completion(speechAuthorized && microphoneAuthorized)
//                }
//            }
//        }
//    }
//}