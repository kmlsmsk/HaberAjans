import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

class AudioRecorderService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _recorderId = 'habercim_recorder';
  bool _isCreated = false;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  int _recordDurationSeconds = 0;
  Timer? _timer;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  int get recordDurationSeconds => _recordDurationSeconds;

  Future<void> _ensureCreated() async {
    if (!_isCreated) {
      try {
        await RecordPlatform.instance.create(_recorderId);
        _isCreated = true;
      } catch (_) {}
    }
  }

  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    await _ensureCreated();
    try {
      return await RecordPlatform.instance.hasPermission(_recorderId);
    } catch (_) {
      return false;
    }
  }

  Future<bool> startRecording({Function(int durationSeconds)? onTick}) async {
    final hasPerm = await checkPermission();
    if (!hasPerm) return false;

    await _ensureCreated();

    try {
      if (await RecordPlatform.instance.isRecording(_recorderId)) {
        await RecordPlatform.instance.stop(_recorderId);
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/habercim_rec_$timestamp.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      );

      await RecordPlatform.instance.start(_recorderId, config, path: filePath);
      _isRecording = true;
      _currentRecordingPath = filePath;
      _recordDurationSeconds = 0;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDurationSeconds++;
        if (onTick != null) {
          onTick(_recordDurationSeconds);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Audio recording error: $e');
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecording() async {
    _timer?.cancel();
    _timer = null;
    try {
      final path = await RecordPlatform.instance.stop(_recorderId);
      _isRecording = false;
      _currentRecordingPath = path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
    }
    return _currentRecordingPath;
  }

  Future<void> playAudio(String path, {VoidCallback? onFinished, VoidCallback? onComplete}) async {
    final callback = onComplete ?? onFinished;
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
    _isPlaying = true;
    await _audioPlayer.play(DeviceFileSource(path));
    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      if (callback != null) callback();
    });
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  void dispose() {
    _timer?.cancel();
    try {
      RecordPlatform.instance.dispose(_recorderId);
    } catch (_) {}
    _audioPlayer.dispose();
  }
}
