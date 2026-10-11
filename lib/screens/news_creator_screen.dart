import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';
import '../services/gemini_api_service.dart';
import '../widgets/model_selector_dropdown.dart';
import '../widgets/result_card.dart';
import 'editorial_check_screen.dart';

class NewsCreatorScreen extends StatefulWidget {
  final String? initialText;

  const NewsCreatorScreen({super.key, this.initialText});

  @override
  State<NewsCreatorScreen> createState() => _NewsCreatorScreenState();
}

class _NewsCreatorScreenState extends State<NewsCreatorScreen> {
  final _rawTextController = TextEditingController();
  final _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageMimeType;

  bool _isGenerating = false;
  String _selectedModel = GeminiModelConfig.defaultNewsModel;
  String _agencyName = ApiKeyStorage.defaultAgency;
  String _universityName = ApiKeyStorage.defaultUniversity;
  String _rectorName = ApiKeyStorage.defaultRector;
  GeminiResponseResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _rawTextController.text = widget.initialText!;
    }
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final model = await ApiKeyStorage.getModelForModule('news');
    final sanitized = GeminiModelConfig.sanitizeModel(model);
    final agency = await ApiKeyStorage.getAgencyName();
    final uni = await ApiKeyStorage.getUniversityName();
    final rector = await ApiKeyStorage.getRectorName();

    if (mounted) {
      setState(() {
        _selectedModel = sanitized;
        _agencyName = agency;
        _universityName = uni;
        _rectorName = rector;
      });
    }
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageMimeType = picked.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçilemedi: $e')),
        );
      }
    }
  }

  void _applyTemplate(String title, String templateText) {
    setState(() {
      _rawTextController.text = templateText;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'$title' şablonu yüklendi."),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _generateNews() async {
    final rawText = _rawTextController.text.trim();
    if (rawText.isEmpty && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ham metin/etkinlik notu girin veya bir fotoğraf ekleyin.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _result = null;
    });

    final res = await GeminiApiService.generateNews(
      rawText: rawText,
      referenceUrl: _urlController.text.trim(),
      imageBytes: _imageBytes,
      imageMimeType: _imageMimeType,
      preferredModel: _selectedModel,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_agencyName Haber Yazarı'),
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
                    moduleType: 'news',
                    onChanged: (model) {
                      setState(() => _selectedModel = model);
                      ApiKeyStorage.saveModel('news', model);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Hızlı Şablonlar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.star, size: 16, color: Color(0xFF003366)),
                  label: const Text('🔬 TÜBİTAK Projesi', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyTemplate(
                    'TÜBİTAK Projesi',
                    '$_universityName Mühendislik ve Fen Fakültesi öğretim üyelerinin hazırladığı kanser araştırmaları projesi TÜBİTAK 1001 programı kapsamında 4.2 milyon TL destek almaya hak kazandı. Rektör $_rectorName, projenin bilim dünyası için gurur verici bir adım olduğunu vurguladı.',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.school, size: 16, color: Color(0xFF003366)),
                  label: const Text('🎓 Akademik Açılış', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyTemplate(
                    'Akademik Açılış',
                    '$_universityName Kültür ve Kongre Merkezinde 2026-2027 Akademik Yılı Açılış Töreni gerçekleştirildi. Törende Rektör $_rectorName, araştırma üniversitesi hedefleri ve yeni projeleri kamuoyuyla paylaştı.',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.park, size: 16, color: Color(0xFF003366)),
                  label: const Text('🌿 Yeşil Kampüs', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyTemplate(
                    'Yeşil Kampüs',
                    '$_universityName, GreenMetric dünya yeşil kampüs sıralamasında derecesini korudu. Güneş enerjisi ve sıfır atık projeleri sergilendi.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Haber Girdisi Kartı
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ham Etkinlik Notları veya Taslak Metin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rawTextController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Etkinliğin kimin tarafından, nerede, ne zaman yapıldığına dair notları veya konuşma özetlerini buraya yapıştırın...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Referans Bağlantı / Kaynak URL (İsteğe bağlı)',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Görsel Ekleme Alanı
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                      if (_imageBytes != null) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _imageBytes = null;
                            _imageMimeType = null;
                          }),
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          label: const Text('Görseli Kaldır', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),

                  // Görsel Önizleme
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Haber Üret Butonu
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF003366),
            ),
            onPressed: _isGenerating ? null : _generateNews,
            icon: _isGenerating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.newspaper),
            label: Text(
              _isGenerating ? '$_agencyName Formatında Yazılıyor...' : '📰 Haberi Oluştur ($_agencyName Formatı)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // Sonuç Alanı
          if (_result != null)
            if (_result!.isSuccess)
              ResultCard(
                title: '📰 $_agencyName Kurumsal Haber Metni',
                content: _result!.text,
                modelUsed: _result!.usedModel,
                defaultDocxTitle: '${_agencyName.replaceAll(' ', '_')}_Haber_Bulteni',
                forwardButtonLabel: '3. Adım: Editoryal Denetime Gönder',
                onForward: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditorialCheckScreen(initialText: _result!.text),
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
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _result!.errorMessage ?? 'Haber oluşturulamadı.',
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
