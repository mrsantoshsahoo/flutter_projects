/// ios code

/// ios code

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Speech Recognition',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: SpeechRecognitionPage(),
//     );
//   }
// }
//
// class SpeechRecognitionPage extends StatefulWidget {
//   @override
//   _SpeechRecognitionPageState createState() => _SpeechRecognitionPageState();
// }
//
// class _SpeechRecognitionPageState extends State<SpeechRecognitionPage> {
//   static const platform = MethodChannel('com.example.voice_overlay');
//   String _text = "Press the button and speak";
//
//   @override
//   void initState() {
//     super.initState();
//     platform.setMethodCallHandler((call) async {
//       if (call.method == 'onVoiceResult') {
//         setState(() {
//           _text = call.arguments;
//         });
//       }
//     });
//   }
//
//   Future<void> _startVoiceOverlay() async {
//     try {
//       await platform.invokeMethod('startVoiceOverlay');
//     } on PlatformException catch (e) {
//       print("Failed to start voice overlay: '${e.message}'.");
//     }
//   }
//
//   Future<void> _stopVoiceOverlay() async {
//     try {
//       await platform.invokeMethod('stopVoiceOverlay');
//     } on PlatformException catch (e) {
//       print("Failed to stop voice overlay: '${e.message}'.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flutter Speech Recognition'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               _text,
//               style: TextStyle(
//                 fontSize: 20.0,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _startVoiceOverlay,
//               child: Text('Start Voice Recognition'),
//             ),
//             ElevatedButton(
//               onPressed: _stopVoiceOverlay,
//               child: Text('Stop Voice Recognition'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

/// android code

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('speech_recognition');
  String _recognizedText = "Press the button and start speaking";
  String _partialText = "";

  Future<void> _startListening() async {
    try {
      await platform.invokeMethod('startListening');
    } on PlatformException catch (e) {
      print("Failed to start listening: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();

    // Listen for speech results from the native side
    platform.setMethodCallHandler((call) async {
      if (call.method == "onSpeechResult") {
        setState(() {
          _recognizedText = call.arguments as String;
        });
      } else if (call.method == "onPartialSpeechResult") {
        setState(() {
          _partialText = call.arguments as String;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Speech to Text"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Text(
              //   "Final Recognized Text: $_recognizedText",
              //   style: TextStyle(fontSize: 16),
              // ),
              SizedBox(height: 20),
              Text(
                "Partial Recognized Text: $_partialText",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startListening,
                child: Text("Start Listening"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// new ios code
//
// import 'dart:async';
// import 'package:flutter/services.dart';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'voice_overlay_plugin.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Voice Overlay Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
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
//   String _status = 'Status: Idle';
//   String _recognizedText = '';
//   String _currentLocale = 'en-US';
//   List<String> languageList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     // _initVoiceOverlay();
//     _listenToVoiceEvents();
//     _listenToStatusUpdates();
//     _getAvailableLanguages();
//   }
//
//   void _initVoiceOverlay() async {
//    await Permission.microphone.request();
//     await VoiceOverlayPlugin.initVoiceOverlay();
//   }
//
//   void _listenToVoiceEvents() {
//     VoiceOverlayPlugin.voiceEventStream.listen((text) {
//       setState(() {
//         _recognizedText = text;
//       });
//     });
//   }
//
//   void _listenToStatusUpdates() {
//     VoiceOverlayPlugin.statusEventStream.listen((status) {
//       setState(() {
//         _status = 'Status: $status';
//       });
//     });
//   }
//
//   void _getAvailableLanguages() async {
//     languageList = await VoiceOverlayPlugin.getAvailableLanguages() ?? [];
//     setState(() {});
//   }
//
//   void _startVoiceOverlay() async {
//     await VoiceOverlayPlugin.startVoiceOverlay(locale: _currentLocale);
//   }
//
//   void _stopVoiceOverlay() async {
//     await VoiceOverlayPlugin.stopVoiceOverlay();
//   }
//
//   void _pauseVoiceOverlay() async {
//     await VoiceOverlayPlugin.pauseVoiceOverlay();
//   }
//
//   void _resetVoiceOverlay() async {
//     await VoiceOverlayPlugin.resetVoiceOverlay();
//   }
//
//   void _setVoiceOverlayLanguage(String locale) async {
//     setState(() {
//       _currentLocale = locale;
//     });
//     await VoiceOverlayPlugin.setVoiceOverlayLanguage(locale);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Voice Overlay Demo'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Text(
//                   'Locale: $_currentLocale',
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   _status,
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Recognized Text:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               _recognizedText,
//               style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _startVoiceOverlay,
//               child: const Text('Start Voice Overlay'),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _stopVoiceOverlay,
//               child: const Text('Stop Voice Overlay'),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _pauseVoiceOverlay,
//               child: const Text('Pause Voice Overlay'),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _resetVoiceOverlay,
//               child: const Text('Reset Voice Overlay'),
//             ),
//             const SizedBox(height: 16),
//             DropdownButton<String>(
//               value: _currentLocale,
//               items: languageList.map((String locale) {
//                 return DropdownMenuItem<String>(
//                   value: locale,
//                   child: Text(locale),
//                 );
//               }).toList(),
//               onChanged: (String? newLocale) {
//                 if (newLocale != null) {
//                   _setVoiceOverlayLanguage(newLocale);
//                 }
//               },
//               isExpanded: true,
//               hint: const Text('Select Language'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
