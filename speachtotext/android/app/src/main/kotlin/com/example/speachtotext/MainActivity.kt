//package com.example.speachtotext
//
//import android.content.Intent
//import android.os.Bundle
//import android.speech.RecognitionListener
//import android.speech.SpeechRecognizer
//import android.speech.RecognizerIntent
//import android.util.Log
//import androidx.activity.ComponentActivity
//import androidx.activity.result.contract.ActivityResultContracts
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.EventChannel
//import io.flutter.plugin.common.MethodChannel.MethodCallHandler
//import io.flutter.plugin.common.MethodChannel.Result
//import io.flutter.plugin.common.EventChannel.EventSink
//import io.flutter.plugin.common.EventChannel.StreamHandler
//
//class MainActivity : FlutterActivity() {
//
//    private val CHANNEL = "com.example.voice_overlay"
//    private val VOICE_EVENT_CHANNEL = "com.example.voice_overlay_stream"
//    private val STATUS_EVENT_CHANNEL = "com.example.reconciliation_status_stream"
//
//    private var speechRecognizer: SpeechRecognizer? = null
//    private var recognizerIntent: Intent? = null
//    private var voiceEventSink: EventSink? = null
//    private var statusEventSink: EventSink? = null
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//            when (call.method) {
//                "initVoiceOverlay" -> initVoiceOverlay(result)
//                "startVoiceOverlay" -> startVoiceOverlay(call.argument("locale") ?: "en-US", result)
//                "setVoiceOverlayLanguage" -> setVoiceOverlayLanguage(call.argument("locale") ?: "en-US")
//                "stopVoiceOverlay" -> stopVoiceOverlay(result)
//                "pauseVoiceOverlay" -> pauseVoiceOverlay(result)
//                "resetVoiceOverlay" -> resetVoiceOverlay()
//                "getAvailableLanguages" -> getAvailableLanguages(result)
//                else -> result.notImplemented()
//            }
//        }
//
//        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_EVENT_CHANNEL).setStreamHandler(object : StreamHandler {
//            override fun onListen(arguments: Any?, events: EventSink?) {
//                voiceEventSink = events
//            }
//
//            override fun onCancel(arguments: Any?) {
//                voiceEventSink = null
//            }
//        })
//
//        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STATUS_EVENT_CHANNEL).setStreamHandler(object : StreamHandler {
//            override fun onListen(arguments: Any?, events: EventSink?) {
//                statusEventSink = events
//            }
//
//            override fun onCancel(arguments: Any?) {
//                statusEventSink = null
//            }
//        })
//    }
//
//    private fun initVoiceOverlay(result: Result) {
//        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
//        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
//            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
//            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
//        }
//        result.success("Voice overlay initialized")
//    }
//
//    private fun startVoiceOverlay(locale: String, result: Result) {
//        recognizerIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
//        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
//            override fun onReadyForSpeech(params: Bundle?) {
//                statusEventSink?.success("Started")
//            }
//
//            override fun onBeginningOfSpeech() {}
//
//            override fun onRmsChanged(rmsdB: Float) {}
//
//            override fun onBufferReceived(buffer: ByteArray?) {}
//
//            override fun onEndOfSpeech() {}
//
//            override fun onError(error: Int) {
//                statusEventSink?.success("Error")
//                Log.e("SpeechRecognizer", "Error: $error")
//            }
//
//            override fun onResults(results: Bundle?) {
//                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
//                matches?.let { voiceEventSink?.success(it.joinToString(", ")) }
//            }
//
//            override fun onPartialResults(partialResults: Bundle?) {
//
//            }
//
//            override fun onEvent(eventType: Int, params: Bundle?) {}
//        })
//        speechRecognizer?.startListening(recognizerIntent)
//        result.success("Voice overlay started")
//    }
//
//    private fun setVoiceOverlayLanguage(locale: String) {
//        recognizerIntent?.putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
//    }
//
//    private fun stopVoiceOverlay(result: Result) {
//        speechRecognizer?.stopListening()
//        result.success("Voice overlay stopped")
//    }
//
//    private fun pauseVoiceOverlay(result: Result) {
//        speechRecognizer?.stopListening()
//        result.success("Voice overlay paused")
//    }
//
//    private fun resetVoiceOverlay() {
//        speechRecognizer?.cancel()
//        statusEventSink?.success("Reset")
//    }
//
//    private fun getAvailableLanguages(result: Result) {
//        val languages = listOf(
//            "en-US", "es-ES", "fr-FR", "de-DE", "it-IT"
//        )
//        result.success(languages)
//    }
//}

package com.example.speachtotext

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "speech_recognition"
    private lateinit var methodChannel: MethodChannel
    private lateinit var speechRecognizer: SpeechRecognizer
    private val REQUEST_RECORD_AUDIO_PERMISSION = 200

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the global MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Set up a listener for MethodChannel calls from Flutter
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    startListening()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Check microphone permission and initialize SpeechRecognizer
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO_PERMISSION)
            } else {
                initializeSpeechRecognizer()
            }
        } else {
            initializeSpeechRecognizer()
        }
    }

    // Initialize the SpeechRecognizer with optimal settings
    private fun initializeSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        val recognitionListener = object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d("SpeechRecognizer", "Ready for speech")
            }

            override fun onBeginningOfSpeech() {
                Log.d("SpeechRecognizer", "Speech started")
            }

            override fun onRmsChanged(rmsdB: Float) {}

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                Log.d("SpeechRecognizer", "Speech ended")
                // Restart listening to make continuous recognition
                startListening()
            }

            override fun onError(error: Int) {
                Log.e("SpeechRecognizer", "Error occurred: $error")
                // Restart listening after an error for continuous recognition
                startListening()
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val recognizedText = matches?.get(0) ?: "No speech detected"
                methodChannel.invokeMethod("onSpeechResult", recognizedText)
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val partialMatches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val partialText = partialMatches?.get(0) ?: ""
                // Send partial results to Flutter
                methodChannel.invokeMethod("onPartialSpeechResult", partialText)
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        }

        speechRecognizer.setRecognitionListener(recognitionListener)
    }

    // Start speech recognition process with optimized settings
    private fun startListening() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
        intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)  // Enable partial results
        intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 500) // Short silence for faster response
        intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500) // Reduce minimum input length
        intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)  // Get results quickly

        speechRecognizer.startListening(intent)
    }

    // Handle microphone permission request results
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initializeSpeechRecognizer()
            } else {
                Log.e("SpeechRecognizer", "Permission denied to record audio")
            }
        }
    }

    // Clean up resources when the activity is destroyed
    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer.destroy()
    }
}
