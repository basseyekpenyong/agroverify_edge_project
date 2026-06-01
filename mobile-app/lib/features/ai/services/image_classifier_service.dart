import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

const _commodityLabels = [
  'maize', 'cassava', 'sorghum', 'rice', 'soy',
  'groundnuts', 'yam', 'millet', 'cocoa', 'palm_oil',
];

const _modelAsset = 'assets/models/commodity_classifier_int8.tflite';
const _inputSize = 224;

class ClassificationResult {
  final String label;
  final double confidence;
  ClassificationResult({required this.label, required this.confidence});
}

class ImageClassifierService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final modelData = await rootBundle.load(_modelAsset);
      _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());
      _isLoaded = true;
    } catch (_) {
      // Model file not yet present — expected during development
      _isLoaded = false;
    }
  }

  bool get isAvailable => _isLoaded && _interpreter != null;

  /// Classify a commodity image. Returns null if model is not loaded.
  Future<ClassificationResult?> classify(String imagePath) async {
    if (!isAvailable) return null;

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final input = _preprocess(decoded);
      final output = List.filled(_commodityLabels.length, 0.0).reshape([1, _commodityLabels.length]);

      _interpreter!.run(input, output);

      final scores = (output[0] as List).cast<double>();
      final maxIdx = scores.indexOf(scores.reduce(max));

      return ClassificationResult(
        label: _commodityLabels[maxIdx],
        confidence: scores[maxIdx],
      );
    } catch (_) {
      return null;
    }
  }

  /// Resize to 224×224, normalize to [0, 1] float32.
  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    return List.generate(1, (_) =>
      List.generate(_inputSize, (y) =>
        List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        }),
      ),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
