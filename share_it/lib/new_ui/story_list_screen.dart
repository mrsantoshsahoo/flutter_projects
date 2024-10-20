import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wifi_iot/wifi_iot.dart';

enum MessageType { text, image, video, audio }

class ChatMessage {
  final MessageType type;
  final String? message;
  final Uint8List? mediaData;
  final String? fileName;

  ChatMessage({
    required this.type,
    this.message,
    this.mediaData,
    this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'message': message,
      'mediaData': mediaData != null ? base64Encode(mediaData!) : null,
      'fileName': fileName,
    };
  }

  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      type: MessageType.values.firstWhere((e) => e.toString() == json['type']),
      message: json['message'],
      mediaData: json['mediaData'] != null ? base64Decode(json['mediaData']) : null,
      fileName: json['fileName'],
    );
  }
}

class ChatPageee extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPageee> {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _portController = TextEditingController();
  TextEditingController _serverController = TextEditingController();
  Socket? _socket;
  ServerSocket? _serverSocket;
  List<ChatMessage> _messages = [];
  bool _isServerRunning = false;
  bool _isClientConnected = false;
  Uint8List _buffer = Uint8List(0);
  int? _expectedLength;

  @override
  void initState() {
    super.initState();
    _portController.text = '8080'; // Default port
  }

  Future<String> _getLocalIp() async {
    try {
      var ip = Platform.isAndroid
          ? await getLocalIPAddress()
          : await WiFiForIoTPlugin.getIP();
      _hostController.text = ip ?? '';
      print("IP address: $ip");
      return ip ?? "0.0.0.0";
    } catch (e) {
      print("Failed to get IP address: $e");
      return "0.0.0.0";
    }
  }

  Future<String?> getLocalIPAddress() async {
    try {
      var interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } catch (e) {
      print('Error retrieving IP address: $e');
    }
    return null;
  }

  Future<void> _startServer({String? ip}) async {
    try {
      _serverSocket = await ServerSocket.bind(ip ?? "0.0.0.0", int.parse(_portController.text));
      setState(() {
        _isServerRunning = true;
      });
      print('TCP server started at ${_serverSocket!.address}:${_serverSocket!.port}.');

      _serverSocket!.listen((Socket socket) {
        print('New client connected: ${socket.address.address}:${socket.port}');
        socket.listen((Uint8List data) {
          _processIncomingData(data);
        }, onError: (error) {
          print('Error: $error');
        }, onDone: () {
          print('Client disconnected');
        });
      });
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  Future<void> _connectToServer() async {
    final host = _hostController.text;
    final port = int.tryParse(_portController.text) ?? 8080;

    try {
      _socket = await Socket.connect(host, port);
      setState(() {
        _isClientConnected = true;
      });

      _socket!.listen((Uint8List data) {
        _processIncomingData(data);
      });

      print("Connected to server at $host:$port");
    } catch (e) {
      print("Could not connect to server: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_socket != null && _messageController.text.isNotEmpty) {
      final message = ChatMessage(type: MessageType.text, message: _messageController.text);

      final messageJson = jsonEncode(message.toJson());
      final messageBytes = utf8.encode(messageJson);

      _socket!.write(messageBytes.length.toString().padLeft(10, '0')); // Send the length of the message
      _socket!.add(messageBytes);

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final message = ChatMessage(
        type: MessageType.image,
        mediaData: imageBytes,
        fileName: pickedFile.name,
      );

      final messageJson = jsonEncode(message.toJson());
      final messageBytes = utf8.encode(messageJson);

      _socket!.write(messageBytes.length.toString().padLeft(10, '0')); // Send length of message
      _socket!.add(messageBytes);

      setState(() {
        _messages.add(message); // Add the sent message locally
      });
    }
  }

  void _processIncomingData(Uint8List data) {
    if (_expectedLength == null) {
      final lengthStr = utf8.decode(data.sublist(0, 10)); // First 10 bytes for length
      _expectedLength = int.tryParse(lengthStr);
      if (_expectedLength == null) return;
      data = data.sublist(10); // Remove length header
    }

    _buffer = Uint8List.fromList(_buffer + data);

    if (_buffer.length >= _expectedLength!) {
      final messageJson = utf8.decode(_buffer);
      final message = ChatMessage.fromJson(jsonDecode(messageJson));

      setState(() {
        _messages.add(message); // Add received message
      });

      _buffer = Uint8List(0); // Reset buffer
      _expectedLength = null; // Reset expected length for next message
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _serverSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCP Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serverController,
                    decoration: const InputDecoration(labelText: 'Server IP'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(labelText: 'Connect IP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _startServer(ip: _serverController.text.isEmpty ? null : _serverController.text);
                  },
                  child: const Text('Start Server'),
                ),
                ElevatedButton(
                  onPressed: _connectToServer,
                  child: const Text('Connect'),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.type == MessageType.text) {
                    return ListTile(title: Text(message.message ?? ''));
                  } else if (message.type == MessageType.image && message.mediaData != null) {
                    return ListTile(
                      title: Text('Image: ${message.fileName}'),
                      subtitle: Image.memory(message.mediaData!),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Enter your message'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _getLocalIp,
                  child: const Text('Get IP'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendImage,
                  child: const Text('Pick Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

