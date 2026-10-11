import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  VoidCallback? onStateChanged;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.5); // Doğal konuşma hızı
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        if (onStateChanged != null) onStateChanged!();
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        if (onStateChanged != null) onStateChanged!();
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        if (onStateChanged != null) onStateChanged!();
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        if (onStateChanged != null) onStateChanged!();
      });
    } catch (e) {
      debugPrint('TTS başlatma hatası: $e');
    }
  }

  /// Markdown ve özel işaretleri temizleyerek doğal Türkçe okur
  static String cleanTextForSpeech(String raw) {
    var text = raw;
    // Markdown başlık ve vurguları kaldır
    text = text.replaceAll(RegExp(r'#+\s*'), '');
    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    text = text.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    // TV etiketlerini kaldır (CAM 1, KJ vb.)
    text = text.replaceAll(RegExp(r'\[CAM\s*\d*\]', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'KJ:.*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'VTR:.*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'===.*?==='), '');
    // Fazla boşluk ve satırları düzenle
    text = text.replaceAll(RegExp(r'\n+'), '. ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  Future<void> speak(String text) async {
    final clean = cleanTextForSpeech(text);
    if (clean.isEmpty) return;

    if (_isPlaying) {
      await stop();
    }

    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.speak(clean);
      _isPlaying = true;
      if (onStateChanged != null) onStateChanged!();
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isPlaying = false;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isPlaying = false;
    if (onStateChanged != null) onStateChanged!();
  }
}
