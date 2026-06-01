import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../services/image_dao.dart';
import '../../ai/services/image_classifier_service.dart';

const _uuid = Uuid();

class PhotoCaptureScreen extends ConsumerStatefulWidget {
  final String transactionId;
  const PhotoCaptureScreen({super.key, required this.transactionId});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  String _imageType = 'commodity';
  bool _saving = false;
  ClassificationResult? _classificationResult;
  final _classifier = ImageClassifierService();

  @override
  void initState() {
    super.initState();
    _classifier.load();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imageId = _uuid.v4();
      final destPath = p.join(dir.path, 'images', '$imageId.jpg');
      await Directory(p.dirname(destPath)).create(recursive: true);

      // Compress to target < 500KB
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        destPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      final finalPath = compressed?.path ?? picked.path;

      // Run commodity classification if image type is 'commodity'
      if (_imageType == 'commodity' && _classifier.isAvailable) {
        final result = await _classifier.classify(finalPath);
        if (mounted) setState(() => _classificationResult = result);
      }

      final dao = ImageDao.fromSingleton();
      await dao.insert(
        id: imageId,
        transactionId: widget.transactionId,
        filePath: finalPath,
        imageType: _imageType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved'), backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving photo: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Add Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.camera_alt, size: 96, color: Colors.white54),
            const SizedBox(height: 24),
            const Text('Photo type:', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _TypeChip(label: 'Commodity', value: 'commodity', selected: _imageType, onTap: (v) => setState(() => _imageType = v)),
                _TypeChip(label: 'Scale Proof', value: 'scale_proof', selected: _imageType, onTap: (v) => setState(() => _imageType = v)),
                _TypeChip(label: 'Delivery', value: 'delivery_evidence', selected: _imageType, onTap: (v) => setState(() => _imageType = v)),
              ],
            ),
            const Spacer(),
            // Classification result banner
            if (_classificationResult != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _classificationResult!.confidence >= 0.7
                      ? AppColors.primary.withValues(alpha: 0.9)
                      : AppColors.warning.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI detected: ${_classificationResult!.label} '
                        '(${(_classificationResult!.confidence * 100).toStringAsFixed(0)}% confidence)',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text('GPS will be embedded in photo metadata', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _saving ? null : _capture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _saving ? Colors.grey : AppColors.primary,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  const _TypeChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Chip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary)),
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }
}
