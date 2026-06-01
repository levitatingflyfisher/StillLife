import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech-to-text wrapper. No cloud calls — uses the device's
/// built-in speech recognizer (Android: SpeechRecognizer, iOS: SFSpeechRecognizer).
class VoiceInputService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  /// Initialize the recognizer. Call once before [listen].
  /// Returns false if permission is denied or STT is unavailable.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(onError: (_) {});
    return _initialized;
  }

  /// Listen for speech and return the final transcript, or null if
  /// unavailable or cancelled. [onPartial] fires with interim results.
  Future<String?> listen({void Function(String partial)? onPartial}) async {
    if (!_initialized && !await initialize()) return null;
    if (_stt.isListening) await _stt.stop();

    String? finalResult;
    final completer = Completer<String?>();

    await _stt.listen(
      onResult: (r) {
        if (r.finalResult) {
          finalResult = r.recognizedWords.isEmpty ? null : r.recognizedWords;
          if (!completer.isCompleted) completer.complete(finalResult);
        } else {
          onPartial?.call(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    // Safety timeout — complete with whatever we have after 35s.
    Future.delayed(const Duration(seconds: 35), () {
      if (!completer.isCompleted) completer.complete(finalResult);
    });

    return completer.future;
  }

  bool get isListening => _stt.isListening;

  Future<void> stop() async {
    await _stt.stop();
  }
}
