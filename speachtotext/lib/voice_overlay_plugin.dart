import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceOverlayPlugin {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.voice_overlay');
  static const EventChannel _voiceEventChannel =
      EventChannel('com.example.voice_overlay_stream');
  static const EventChannel _statusEventChannel =
      EventChannel('com.example.reconciliation_status_stream');

  static final Stream<String> _voiceEventStream = _voiceEventChannel
      .receiveBroadcastStream()
      .map((event) => event as String)
      .handleError((error) {
    debugPrint("Error in voiceEventStream: $error");
  });
  static final Stream<String> _statusEventStream = _statusEventChannel
      .receiveBroadcastStream()
      .map((event) => event as String)
      .handleError((error) {
    debugPrint("Error in statusEventStream: $error");
  });

  /// Initializes the voice overlay with default settings.
  static Future<void> initVoiceOverlay() async {
    try {
      await _methodChannel.invokeMethod('initVoiceOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to initialize voice overlay: '${e.message}'.");
    }
  }

  /// Starts the voice overlay with the specified locale.
  static Future<void> startVoiceOverlay({String locale = 'en-US'}) async {
    try {
      await _methodChannel
          .invokeMethod('startVoiceOverlay', {'locale': locale});
    } on PlatformException catch (e) {
      debugPrint("Failed to start voice overlay: '${e.message}'.");
    }
  }

  /// Sets the language for the voice overlay.
  static Future<void> setVoiceOverlayLanguage(String locale) async {
    try {
      await _methodChannel
          .invokeMethod('setVoiceOverlayLanguage', {'locale': locale});
    } on PlatformException catch (e) {
      debugPrint("Failed to set voice overlay language: '${e.message}'.");
    }
  }

  /// Stops the voice overlay.
  static Future<void> stopVoiceOverlay() async {
    try {
      await _methodChannel.invokeMethod('stopVoiceOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop voice overlay: '${e.message}'.");
    }
  }

  /// Pauses the voice overlay.
  static Future<void> pauseVoiceOverlay() async {
    try {
      await _methodChannel.invokeMethod('pauseVoiceOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to pause voice overlay: '${e.message}'.");
    }
  }

  /// Resets the voice overlay.
  static Future<void> resetVoiceOverlay() async {
    try {
      await _methodChannel.invokeMethod('resetVoiceOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to reset voice overlay: '${e.message}'.");
    }
  }

  /// Get available languages.
  static Future<List<String>?> getAvailableLanguages() async {
    try {
      final List<dynamic>? languages = await _methodChannel
          .invokeMethod<List<dynamic>>('getAvailableLanguages');
      return languages?.cast<String>();
    } on PlatformException catch (e) {
      debugPrint("Failed to get available languages: '${e.message}'.");
      return null;
    }
  }

  /// Stream of voice recognition results.
  static Stream<String> get voiceEventStream => _voiceEventStream;

  /// Stream of reconciliation status updates.
  static Stream<String> get statusEventStream => _statusEventStream;
}
