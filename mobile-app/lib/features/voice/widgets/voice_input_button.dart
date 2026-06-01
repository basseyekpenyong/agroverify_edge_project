import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../services/audio_recorder_service.dart';
import '../services/whisper_service.dart';

enum _VoiceState { idle, recording, processing }

class VoiceInputButton extends StatefulWidget {
  final WhisperLanguage language;
  final void Function(String transcript) onTranscript;
  final bool whisperAvailable;

  const VoiceInputButton({
    super.key,
    required this.language,
    required this.onTranscript,
    this.whisperAvailable = false,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorderService();
  final _whisper = WhisperService();
  _VoiceState _state = _VoiceState.idle;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _whisper.load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _recorder.dispose();
    _whisper.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_state == _VoiceState.processing) return;

    if (_state == _VoiceState.recording) {
      await _stopAndTranscribe();
      return;
    }

    // Check microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for voice input')),
        );
      }
      return;
    }

    setState(() => _state = _VoiceState.recording);
    await _recorder.startRecording();
  }

  Future<void> _stopAndTranscribe() async {
    setState(() => _state = _VoiceState.processing);
    final wavPath = await _recorder.stopRecording();

    if (wavPath == null) {
      setState(() => _state = _VoiceState.idle);
      return;
    }

    if (!_whisper.isAvailable) {
      // Model not loaded — show placeholder message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice model not yet loaded. Recording saved — will transcribe when model is ready.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() => _state = _VoiceState.idle);
      return;
    }

    final transcript = await _whisper.transcribe(wavPath, widget.language);
    if (mounted) {
      if (transcript != null && transcript.isNotEmpty) {
        widget.onTranscript(transcript);
      }
      setState(() => _state = _VoiceState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _state == _VoiceState.processing
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Icon(
                  _state == _VoiceState.recording ? Icons.stop_circle : Icons.mic_none,
                  size: 24,
                  color: _state == _VoiceState.recording
                      ? Color.lerp(AppColors.error, Colors.red.shade900, _pulse.value)!
                      : AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}
