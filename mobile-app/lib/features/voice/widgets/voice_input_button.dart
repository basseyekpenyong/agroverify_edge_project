import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../services/whisper_service.dart';

enum _VoiceState { idle, recording }

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
  final _whisper = WhisperService();
  _VoiceState _state = _VoiceState.idle;
  bool _sttChecked = false;
  bool _sttAvailable = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    // Lazy-load: don't initialize on widget creation, only on first tap.
  }

  @override
  void dispose() {
    _pulse.dispose();
    _whisper.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    if (_sttChecked) return;
    await _whisper.load();
    if (mounted) setState(() { _sttChecked = true; _sttAvailable = _whisper.isAvailable; });
  }

  Future<void> _onTap() async {
    if (_state == _VoiceState.recording) {
      await _whisper.stopListening();
      if (mounted) setState(() => _state = _VoiceState.idle);
      return;
    }

    await _ensureLoaded();
    if (!_sttAvailable) return; // button hidden via build(); guard just in case

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
    await _whisper.startListening(widget.language, (transcript) {
      if (mounted) {
        widget.onTranscript(transcript);
        setState(() => _state = _VoiceState.idle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide button entirely before we've checked, or if STT is unavailable.
    if (_sttChecked && !_sttAvailable) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
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
