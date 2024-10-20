import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ChatProvider with ChangeNotifier {
  Socket? _socket;
  ServerSocket? _serverSocket;
  List<ChatMessage> _messages = [];
  bool _isServerRunning = false;
  bool _isClientConnected = false;
  TextEditingController messageController = TextEditingController();
  TextEditingController hostController = TextEditingController();
  Uint8List _buffer = Uint8List(0);
  int? _expectedLength;
  final int _port = 8080;

  List<ChatMessage> get messages => _messages;

  Future<void> init() async {
   await getLocalIp();
   startServer();
  }

  Future<void> startServer() async {
    try {
      _serverSocket = await ServerSocket.bind("0.0.0.0", _port);
      debugPrint(
          'TCP server started at ${_serverSocket!.address}:${_serverSocket!.port}.');
      _serverSocket!.listen((Socket socket) {
        debugPrint(
            'New client connected: ${socket.address.address}:${socket.port}');
        socket.listen((Uint8List data) {
          _processIncomingData(data);
          notifyListeners();
        }, onError: (error) {
          debugPrint('Error: $error');
        }, onDone: () {
          debugPrint('Client disconnected');
        });
      });
    } catch (e) {
      debugPrint('Error starting server: $e');
    }
    notifyListeners();
  }

  void _processIncomingData(Uint8List data) {
    if (_expectedLength == null) {
      final lengthStr =
          utf8.decode(data.sublist(0, 10)); // First 10 bytes for length
      _expectedLength = int.tryParse(lengthStr);
      if (_expectedLength == null) return;
      data = data.sublist(10); // Remove length header
    }

    _buffer = Uint8List.fromList(_buffer + data);

    if (_buffer.length >= _expectedLength!) {
      final messageJson = utf8.decode(_buffer);
      final message = ChatMessage.fromJson(jsonDecode(messageJson));

      _messages.add(message); // Add received message

      _buffer = Uint8List(0); // Reset buffer
      _expectedLength = null; // Reset expected length for next message
    }
    notifyListeners();
  }

  Future<void> connectToServer() async {
    final host = hostController.text;

    try {
      _socket = await Socket.connect(host, _port);
      _isClientConnected = true;
      if (_socket == null) return;
      _socket!.listen((Uint8List data) {
        _processIncomingData(data);
      });
      notifyListeners();
      debugPrint("Connected to server at $host:$_port");
    } catch (e) {
      debugPrint("Could not connect to server: $e");
    }
    notifyListeners();
  }

  Future<void> sendMessage() async {
    if (_socket == null) return;
    if (_socket != null && messageController.text.isNotEmpty) {
      final message =
          ChatMessage(type: MessageType.text, message: messageController.text);

      final messageJson = jsonEncode(message.toJson());
      final messageBytes = utf8.encode(messageJson);
      _socket!.write(messageBytes.length
          .toString()
          .padLeft(10, '0')); // Send the length of the message
      _socket!.add(messageBytes);

      _messages.add(message);
      messageController.clear();
      notifyListeners();
    }
  }

  Future<void> sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // final pickedFiles = await picker.pickMultiImage().then((v){
    //   print(v.length);
    // });
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final message = ChatMessage(
        type: MessageType.image,
        mediaData: imageBytes,
        fileName: pickedFile.name,
      );

      final messageJson = jsonEncode(message.toJson());
      final messageBytes = utf8.encode(messageJson);
      if (_socket == null) return;
      _socket!.write(messageBytes.length
          .toString()
          .padLeft(10, '0')); // Send length of message
      _socket!.add(messageBytes);
      _messages.add(message); // Add the sent message locally
    }
    notifyListeners();
  }

  Future<void> getLocalIp() async {
    try {
      var ip = Platform.isAndroid
          ? await getLocalIPAddress()
          : await WiFiForIoTPlugin.getIP();
      hostController = TextEditingController(text: ip);
      debugPrint("IP address: $ip");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to get IP address: $e");
    }
    notifyListeners();
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
      debugPrint('Error retrieving IP address: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _socket?.close();
    _serverSocket?.close();
    super.dispose();
  }
}

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
      mediaData:
          json['mediaData'] != null ? base64Decode(json['mediaData']) : null,
      fileName: json['fileName'],
    );
  }
}
