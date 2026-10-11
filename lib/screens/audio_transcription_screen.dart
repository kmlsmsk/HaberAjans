import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';
import '../services/audio_recorder_service.dart';
import '../services/gemini_api_service.dart';
import '../widgets/model_selector_dropdown.dart';
import '../widgets/result_card.dart';
import 'news_creator_screen.dart';

class AudioTranscriptionScreen extends StatefulWidget {
  const AudioTranscriptionScreen({super.key});

  @override
  State<AudioTranscriptionScreen> createState() => _AudioTranscriptionScreenState();
}

class _AudioTranscriptionScreenState extends State<AudioTranscriptionScreen> with SingleTickerProviderStateMixin {
  final AudioRecorderService _audioService = AudioRecorderService();

  String? _selectedFilePath;
  String? _selectedFileName;
  int _audioDurationSeconds = 0;
  bool _isProcessing = false;
  String _selectedModel = GeminiModelConfig.defaultAudioModel;
  GeminiResponseResult? _result;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadDefaultModel();
  }

  Future<void> _loadDefaultModel() async {
    final model = await ApiKeyStorage.getModelForModule('audio');
    if (mounted) {
      setState(() {
        _selectedModel = model;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleLiveRecording() async {
    if (_audioService.isRecording) {
      final path = await _audioService.stopRecording();
      setState(() {
        _selectedFilePath = path;
        _selectedFileName = 'Canlı Ses Kaydı (${_formatDuration(_audioDurationSeconds)})';
      });
    } else {
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
        _audioDurationSeconds = 0;
        _result = null;
      });

      final success = await _audioService.startRecording(onTick: (seconds) {
        if (mounted) {
          setState(() {
            _audioDurationSeconds = seconds;
          });
        }
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon erişim izni alınamadı veya kayıt başlatılamadı.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {});
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _selectedFilePath = file.path;
        _selectedFileName = result.files.single.name;
        _audioDurationSeconds = 0;
        _result = null;
      });
    }
  }

  Future<void> _processAudio() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    final file = File(_selectedFilePath!);
    final bytes = await file.readAsBytes();
    final ext = _selectedFilePath!.split('.').last.toLowerCase();
    String mime = 'audio/mp4';
    if (ext == 'mp3') mime = 'audio/mp3';
    if (ext == 'wav') mime = 'audio/wav';
    if (ext == 'aac') mime = 'audio/aac';
    if (ext == 'ogg') mime = 'audio/ogg';

    final res = await GeminiApiService.transcribeAudio(
      audioBytes: bytes,
      mimeType: mime,
      preferredModel: _selectedModel,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _result = res;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_selectedFilePath == null) return;
    if (_audioService.isPlaying) {
      await _audioService.pauseAudio();
    } else {
      await _audioService.playAudio(_selectedFilePath!, onComplete: () {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses Çözümleme Asistanı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model Seçici Kartı
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_suggest, color: Color(0xFF003366), size: 20),
                      const SizedBox(width: 8),
                      Text('Kullanılan Model', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ModelSelectorDropdown(
                    selectedModelId: _selectedModel,
                    moduleType: 'audio',
                    onChanged: (model) => setState(() => _selectedModel = model),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Canlı Mikrofon Kayıt Alanı Kartı
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'Canlı Ses Kaydı veya Dosya Seçimi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ders, röportaj veya toplantı sesini doğrudan kaydedin ya da cihazınızdan yükleyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Nabız Efektli Mikrofon Butonu
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = _audioService.isRecording ? 1.0 + (_pulseController.value * 0.12) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onTap: _toggleLiveRecording,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _audioService.isRecording ? Colors.redAccent : const Color(0xFF003366),
                              boxShadow: [
                                BoxShadow(
                                  color: (_audioService.isRecording ? Colors.red : const Color(0xFF003366)).withAlpha(80),
                                  blurRadius: 18,
                                  spreadRadius: _audioService.isRecording ? 4 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _audioService.isRecording ? Icons.stop : Icons.mic,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Süre Sayacı ve Durum
                  Text(
                    _formatDuration(_audioDurationSeconds),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _audioService.isRecording
                        ? 'Kayıt yapılıyor... (Durdurmak için dokunun)'
                        : 'Kayda başlamak için mikrofona dokunun',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _audioService.isRecording ? Colors.red : Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('VEYA', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dosya Seçme Butonu
                  OutlinedButton.icon(
                    onPressed: _audioService.isRecording ? null : _pickAudioFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Cihazdan Ses Dosyası Seç'),
                  ),

                  // Seçili Dosya / Kayıt Bilgi Kutusu
                  if (_selectedFilePath != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A3E0).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00A3E0).withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _audioService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: const Color(0xFF003366),
                              size: 32,
                            ),
                            onPressed: _togglePlayback,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName ?? 'Ses Kaydı',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedFilePath!,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              _audioService.stopAudio();
                              setState(() {
                                _selectedFilePath = null;
                                _selectedFileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Çözümlemeyi Başlat Butonu
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF003366),
            ),
            onPressed: (_selectedFilePath == null || _isProcessing || _audioService.isRecording)
                ? null
                : _processAudio,
            icon: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt),
            label: Text(
              _isProcessing ? 'Gemini AI Sesi Çözümlüyor...' : '🚀 Çözümlemeyi Başlat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // Sonuç Alanı
          if (_result != null)
            if (_result!.isSuccess)
              ResultCard(
                title: '🎙️ Düzenlenmiş ve İyileştirilmiş Metin',
                content: _result!.text,
                modelUsed: _result!.usedModel,
                defaultDocxTitle: 'Ses_Cozumleme_Sonucu',
                forwardButtonLabel: '2. Adım: Haber Yazarına Aktar',
                onForward: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsCreatorScreen(initialText: _result!.text),
                    ),
                  );
                },
              )
            else
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _result!.errorMessage ?? 'Bir hata oluştu.',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
