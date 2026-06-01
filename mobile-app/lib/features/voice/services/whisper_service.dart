import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fftea/fftea.dart';

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
}

class WhisperService {
  Interpreter? _interpreter;
  Map<String, String>? _vocab;
  bool _isLoaded = false;

  static const _modelAsset = 'assets/models/whisper_tiny_int8.tflite';
  static const _vocabAsset = 'assets/models/whisper_vocab.json';

  // Whisper audio constants
  static const _sampleRate = 16000;
  static const _nMels = 80;
  static const _nFft = 400;
  static const _hopLength = 160;
  static const _chunkLength = 30; // seconds
  static const _nSamples = _sampleRate * _chunkLength;
  static const _nFrames = _nSamples ~/ _hopLength;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final modelData = await rootBundle.load(_modelAsset);
      _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());

      final vocabJson = await rootBundle.loadString(_vocabAsset);
      _vocab = Map<String, String>.from(jsonDecode(vocabJson));

      _isLoaded = true;
    } catch (_) {
      _isLoaded = false;
    }
  }

  bool get isAvailable => _isLoaded && _interpreter != null;

  Future<String?> transcribe(String wavPath, WhisperLanguage language) async {
    if (!isAvailable) return null;
    try {
      final audioBytes = await File(wavPath).readAsBytes();
      final samples = _decodeWav(audioBytes);
      final mel = _computeMelSpectrogram(samples);
      final outputSize = _interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b);
      final output = List.filled(outputSize, 0).reshape(_interpreter!.getOutputTensor(0).shape);
      _interpreter!.run(mel, output);
      return _decodeTokens(output);
    } catch (_) {
      return null;
    }
  }

  /// Decode 16-bit PCM WAV to float32 samples in [-1, 1].
  Float32List _decodeWav(List<int> bytes) {
    // Skip WAV header (44 bytes standard)
    final dataStart = _findDataChunk(bytes);
    final pcm = bytes.sublist(dataStart);
    final samples = Float32List(pcm.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      final lo = pcm[i * 2];
      final hi = pcm[i * 2 + 1];
      final s16 = (hi << 8) | lo;
      samples[i] = (s16 >= 0x8000 ? s16 - 0x10000 : s16) / 32768.0;
    }
    // Pad or trim to exactly _nSamples
    if (samples.length >= _nSamples) return Float32List.sublistView(samples, 0, _nSamples);
    final padded = Float32List(_nSamples);
    padded.setAll(0, samples);
    return padded;
  }

  int _findDataChunk(List<int> bytes) {
    for (var i = 0; i < bytes.length - 8; i++) {
      if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 && bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) {
        return i + 8; // skip 'data' + 4-byte size
      }
    }
    return 44; // fallback
  }

  /// Compute log-mel spectrogram — shape [1, 80, 3000].
  List _computeMelSpectrogram(Float32List samples) {
    final fft = FFT(_nFft);
    final window = _hammingWindow(_nFft);
    final melFilters = _buildMelFilterbank(_nMels, _nFft ~/ 2 + 1, _sampleRate.toDouble());

    final nFrames = (samples.length - _nFft) ~/ _hopLength + 1;
    final capped = math.min(nFrames, _nFrames);

    // [nMels, nFrames]
    final melSpec = List.generate(_nMels, (_) => List.filled(_nFrames, 0.0));

    for (var frame = 0; frame < capped; frame++) {
      final start = frame * _hopLength;
      final windowed = Float64List(_nFft);
      for (var i = 0; i < _nFft; i++) {
        windowed[i] = (start + i < samples.length ? samples[start + i] : 0.0) * window[i];
      }

      final spectrum = fft.realFft(windowed);
      final magnitudes = List.generate(_nFft ~/ 2 + 1, (i) {
        final re = spectrum[i].x;
        final im = spectrum[i].y;
        return re * re + im * im; // power spectrum
      });

      for (var m = 0; m < _nMels; m++) {
        var energy = 0.0;
        for (var k = 0; k < magnitudes.length; k++) {
          energy += melFilters[m][k] * magnitudes[k];
        }
        melSpec[m][frame] = math.log(math.max(energy, 1e-10));
      }
    }

    // Normalize to [-1, 1] (Whisper normalization)
    final allValues = melSpec.expand((row) => row).toList();
    final maxVal = allValues.reduce(math.max);
    for (var m = 0; m < _nMels; m++) {
      for (var t = 0; t < _nFrames; t++) {
        melSpec[m][t] = math.max(melSpec[m][t], maxVal - 8.0);
        melSpec[m][t] = (melSpec[m][t] + 4.0) / 4.0;
      }
    }

    // Return as [1, 80, 3000]
    return [melSpec];
  }

  Float64List _hammingWindow(int n) {
    final w = Float64List(n);
    for (var i = 0; i < n; i++) {
      w[i] = 0.54 - 0.46 * math.cos(2 * math.pi * i / (n - 1));
    }
    return w;
  }

  List<List<double>> _buildMelFilterbank(int nMels, int nFft, double sampleRate) {
    double hzToMel(double hz) => 2595.0 * math.log(1 + hz / 700) / math.log(10);
    double melToHz(double mel) => 700 * (math.pow(10, mel / 2595.0) - 1);

    final melMin = hzToMel(0);
    final melMax = hzToMel(sampleRate / 2);
    final melPoints = List.generate(nMels + 2, (i) => melMin + i * (melMax - melMin) / (nMels + 1));
    final hzPoints = melPoints.map(melToHz).toList();
    final binPoints = hzPoints.map((hz) => (hz * (_nFft) / sampleRate).round()).toList();

    return List.generate(nMels, (m) {
      final filter = List.filled(nFft, 0.0);
      for (var k = binPoints[m]; k < binPoints[m + 1]; k++) {
        if (k >= 0 && k < nFft) filter[k] = (k - binPoints[m]) / (binPoints[m + 1] - binPoints[m]);
      }
      for (var k = binPoints[m + 1]; k < binPoints[m + 2]; k++) {
        if (k >= 0 && k < nFft) filter[k] = (binPoints[m + 2] - k) / (binPoints[m + 2] - binPoints[m + 1]);
      }
      return filter;
    });
  }

  String _decodeTokens(dynamic output) {
    if (_vocab == null) return '';
    final tokens = (output is List) ? output.expand((e) => e is List ? e : [e]).toList() : [];
    final buffer = StringBuffer();
    for (final t in tokens) {
      final s = _vocab![t.toString()];
      if (s != null && !s.startsWith('<')) buffer.write(s);
    }
    return buffer.toString().trim();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
