import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'voice_input_${DateTime.now().millisecondsSinceEpoch}.wav');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Whisper requires 16kHz
        numChannels: 1,    // Mono
        bitRate: 256000,
      ),
      path: path,
    );

    return path;
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() => _recorder.dispose();
}
