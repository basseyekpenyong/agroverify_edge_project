import 'package:speech_to_text/speech_to_text.dart' as stt;

enum WhisperLanguage { hausa, igbo, yoruba, pidgin }

extension WhisperLanguageX on WhisperLanguage {
  String get code => switch (this) {
        WhisperLanguage.hausa => 'ha',
        WhisperLanguage.igbo => 'ig',
        WhisperLanguage.yoruba => 'yo',
        WhisperLanguage.pidgin => 'pcm',
      };

  String get label => switch (this) {
        WhisperLanguage.hausa => 'Hausa',
        WhisperLanguage.igbo => 'Igbo',
        WhisperLanguage.yoruba => 'Yoruba',
        WhisperLanguage.pidgin => 'Pidgin English',
      };

  // BCP-47 locale used by Android SpeechRecognizer
  String get localeId => switch (this) {
        WhisperLanguage.hausa => 'ha-NG',
        WhisperLanguage.igbo => 'ig-NG',
        WhisperLanguage.yoruba => 'yo-NG',
        WhisperLanguage.pidgin => 'en-NG',
      };
}

class WhisperService {
  final _speech = stt.SpeechToText();
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;
    _isLoaded = await _speech.initialize(
      onError: (_) {},
    );
  }

  bool get isAvailable => _isLoaded;

  /// Starts streaming speech recognition. Calls [onResult] with the final
  /// recognized text. Call [stopListening] to end the session.
  Future<void> startListening(
    WhisperLanguage language,
    void Function(String transcript) onResult,
  ) async {
    if (!_isLoaded) return;

    // Try the target locale; fall back to device default if unavailable.
    final available = await _speech.locales();
    final targetLocale = language.localeId;
    final localeId = available.any((l) => l.localeId == targetLocale)
        ? targetLocale
        : null; // null → device default

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
    _isLoaded = false;
  }
}
