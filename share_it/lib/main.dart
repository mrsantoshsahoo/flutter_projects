// import 'package:flutter/material.dart';
// import 'new_ui/chat_provider.dart';
// import 'new_ui/connect_screen.dart';
// import 'package:provider/provider.dart';
//
//
// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ChatProvider()..init()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       title: 'Socket Chat',
//       home: ConnectScreen(),
//     );
//   }
// }
//
//


import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Web Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TTSWidget(),
    );
  }
}

class TTSWidget extends StatefulWidget {
  @override
  _TTSWidgetState createState() => _TTSWidgetState();
}

class _TTSWidgetState extends State<TTSWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _loading = false;

  Future<void> synthesizeAndPlayAudio(String text) async {
    setState(() {
      _loading = true;
    });

    try {
      // Replace with your backend URL or Google TTS API
      String url = 'http://127.0.0.1:8000/synthesize/';
      var body = json.encode({
        "text": text,
      });

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Assuming API response contains base64 audio
        String base64Audio = data['audio'];
        Uint8List audioBytes = base64.decode(base64Audio);

        // Web-specific audio playing
        await _audioPlayer.play(BytesSource(audioBytes));
      } else {
        print("Error fetching audio: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text to Speech Web'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onSubmitted: (text) {
                synthesizeAndPlayAudio(text);
              },
              decoration: InputDecoration(
                labelText: 'Enter text to synthesize',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                synthesizeAndPlayAudio("Many animals find");
              },
              child: Text(_loading ? 'Loading...' : 'Synthesize & Play'),
            ),
          ],
        ),
      ),
    );
  }
}
