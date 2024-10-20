
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: VoiceOverlayScreen(),
//     );
//   }
// }
//
// class VoiceOverlayScreen extends StatefulWidget {
//   @override
//   _VoiceOverlayScreenState createState() => _VoiceOverlayScreenState();
// }
//
// class _VoiceOverlayScreenState extends State<VoiceOverlayScreen> {
//   static const platform = MethodChannel('com.example.voice_overlay');
//   String _result = '';
//
//   @override
//   void initState() {
//     super.initState();
//
//     platform.setMethodCallHandler((call) async {
//       if (call.method == 'onVoiceResult') {
//         setState(() {
//           _result = call.arguments as String;
//         });
//       }
//     });
//   }
//
//   Future<void> _startVoiceOverlay() async {
//     try {
//       final String result = await platform.invokeMethod('startVoiceOverlay');
//       print(result);
//     } on PlatformException catch (e) {
//       print("Failed to start voice overlay: '${e.message}'.");
//     }
//   }
//
//   Future<void> _stopVoiceOverlay() async {
//     try {
//       final String result = await platform.invokeMethod('stopVoiceOverlay');
//       print(result);
//     } on PlatformException catch (e) {
//       print("Failed to stop voice overlay: '${e.message}'.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Voice Overlay Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text('Result: $_result'),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _startVoiceOverlay,
//               child: Text('Start Voice Overlay'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _stopVoiceOverlay,
//               child: Text('Stop Voice Overlay'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

///



///// search stt code
//import UIKit
//import Flutter
//import InstantSearchVoiceOverlay
//import Speech
//import AVFoundation
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//    private var voiceOverlay: VoiceOverlayController?=nil
//     var voiceOverlayChannel: FlutterMethodChannel!
//
//    override func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        let controller = window?.rootViewController as! FlutterViewController
//        voiceOverlay=VoiceOverlayController()
//        // Set up method channel
//        voiceOverlayChannel = FlutterMethodChannel(name: "com.example.voice_overlay",
//                                                    binaryMessenger: controller.binaryMessenger)
//        voiceOverlayChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
//            if call.method == "startVoiceOverlay" {
//                self?.requestPermissions { granted in
//                    if granted {
//                        self?.startVoiceOverlay(result: result)
//                    } else {
//                        result(FlutterError(code: "PERMISSION_DENIED",
//                                            message: "Microphone or speech recognition permission denied",
//                                            details: nil))
//                    }
//                }
//            } else if call.method == "stopVoiceOverlay" {
//                self?.stopVoiceOverlay(result: result)
//            } else {
//                result(FlutterMethodNotImplemented)
//            }
//        }
//
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//
//    private func startVoiceOverlay(result: @escaping FlutterResult) {
//        let controller = window?.rootViewController as! FlutterViewController
////        voiceOverlay?.settings.autoStart.toggle();
//        voiceOverlay?.start(on: controller, textHandler: { texts, finall, dataa in
//
//            self.voiceOverlayChannel.invokeMethod("onVoiceResult", arguments: texts)
//
//            print("text \(texts)")
//            print("text \(finall)")
//        }, errorHandler: { error in
//
//        }, resultScreenHandler: { data in
//            print("final text \(data)")
//
//        })
//
////        voiceOverlay?.start(on:controller ,textHandler: { texts, finals, dataa  in
////            print("text \(texts)")
////        } ,errorHandler: { error in
////
////        })
//
//
//    }
//
//    private func stopVoiceOverlay(result: @escaping FlutterResult) {
//
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