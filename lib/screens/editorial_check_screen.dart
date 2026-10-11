import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';
import '../services/gemini_api_service.dart';
import '../services/docx_generator_service.dart';
import '../services/tts_service.dart';
import '../services/saved_content_service.dart';
import '../widgets/model_selector_dropdown.dart';
import 'tv_news_screen.dart';

class EditorialCheckScreen extends StatefulWidget {
  final String? initialText;

  const EditorialCheckScreen({super.key, this.initialText});

  @override
  State<EditorialCheckScreen> createState() => _EditorialCheckScreenState();
}

class _EditorialCheckScreenState extends State<EditorialCheckScreen> {
  final _newsTextController = TextEditingController();
  bool _isChecking = false;
  String _selectedModel = GeminiModelConfig.defaultEditorialModel;
  String _agencyName = ApiKeyStorage.defaultAgency;
  GeminiResponseResult? _result;

  // TTS ve Kayıt Yönetimi
  final _tts = TtsService();
  bool _isSpeaking = false;
  SavedNewsItem? _currentLoadedItem;
  List<SavedNewsItem> _savedNewsList = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _newsTextController.text = widget.initialText!;
    }
    _initTts();
    _loadSettings();
    _loadSavedNews();
  }

  Future<void> _initTts() async {
    await _tts.init();
    _tts.onStateChanged = () {
      if (mounted) {
        setState(() {
          _isSpeaking = _tts.isPlaying;
        });
      }
    };
  }

  Future<void> _loadSettings() async {
    final model = await ApiKeyStorage.getModelForModule('editorial');
    final agency = await ApiKeyStorage.getAgencyName();
    if (mounted) {
      setState(() {
        _selectedModel = GeminiModelConfig.sanitizeModel(model);
        _agencyName = agency;
      });
    }
  }

  Future<void> _loadSavedNews() async {
    final list = await SavedContentService.getSavedNews();
    if (mounted) {
      setState(() {
        _savedNewsList = list;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _newsTextController.dispose();
    super.dispose();
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$label panoya kopyalandı!'),
          ],
        ),
        backgroundColor: const Color(0xFF003366),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportDocx(String text, String title) async {
    try {
      final file = await DocxGeneratorService.createDocxFile(
        title: title,
        content: text,
      );
      if (!mounted) return;
      Share.shareXFiles([XFile(file.path)], text: 'HaberVAR - $title');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word oluşturulamadı: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleSpeech(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
    } else {
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seslendirilecek metin bulunamadı.')),
        );
        return;
      }
      await _tts.speak(text);
    }
  }

  // --- KAYDETME & GÜNCELLEME (SADECE NİHAİ HABERİ KAYDEDER) ---
  Future<void> _saveOrUpdateNews(String content, String report) async {
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek nihai haber metni bulunamadı.')),
      );
      return;
    }

    String defaultTitle = 'Haber_${DateFormat('dd.MM.yyyy_HH:mm').format(DateTime.now())}';
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        defaultTitle = trimmed.replaceAll('#', '').trim();
        break;
      }
    }

    final isUpdating = _currentLoadedItem != null;
    final titleController = TextEditingController(text: isUpdating ? _currentLoadedItem!.title : defaultTitle);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isUpdating ? 'Nihai Haberi Güncelle' : 'Nihai Haberi Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Haber Başlığı:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isUpdating ? 'Güncelle' : 'Kaydet', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final title = titleController.text.trim().isEmpty ? defaultTitle : titleController.text.trim();
      if (isUpdating) {
        _currentLoadedItem!.title = title;
        _currentLoadedItem!.content = content;
        _currentLoadedItem!.report = report;
        _currentLoadedItem!.updatedAt = DateTime.now();
        await SavedContentService.saveNews(_currentLoadedItem!);
      } else {
        final newItem = SavedNewsItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          content: content,
          report: report,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _currentLoadedItem = newItem;
        await SavedContentService.saveNews(newItem);
      }
      await _loadSavedNews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? 'Nihai haber güncellendi!' : 'Nihai haber başarıyla kaydedildi!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  // --- KAYITLI HABERLER LİSTESİ DİYALOĞU ---
  Future<void> _showSavedNewsDialog() async {
    await _loadSavedNews();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Color(0xFF003366)),
                        SizedBox(width: 8),
                        Text('Kayıtlı Nihai Haberler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                if (_savedNewsList.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Henüz kaydedilmiş nihai haber bulunmuyor.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _savedNewsList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, idx) {
                        final item = _savedNewsList[idx];
                        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.updatedAt);
                        return ListTile(
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: Color(0xFF00A3E0)),
                                tooltip: 'Yükle',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _currentLoadedItem = item;
                                    _newsTextController.text = item.content;
                                    _result = GeminiResponseResult(
                                      isSuccess: true,
                                      text: item.content,
                                      usedModel: 'Kayıtlı Veri',
                                      structuredSections: {
                                        'report': item.report,
                                        'changelog': '',
                                        'editedText': item.content,
                                      },
                                    );
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Sil',
                                onPressed: () async {
                                  await SavedContentService.deleteNews(item.id);
                                  final updated = await SavedContentService.getSavedNews();
                                  setSheetState(() {
                                    _savedNewsList = updated;
                                  });
                                  setState(() {
                                    _savedNewsList = updated;
                                    if (_currentLoadedItem?.id == item.id) {
                                      _currentLoadedItem = null;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkEditorial() async {
    final text = _newsTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen denetlenecek haber metnini giriniz.')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _result = null;
    });

    final res = await GeminiApiService.editorialCheck(
      newsText: text,
      preferredModel: _selectedModel,
    );

    if (mounted) {
      setState(() {
        _isChecking = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final structured = _result?.structuredSections;
    final report = structured?['report'] ?? '';
    final changelog = structured?['changelog'] ?? '';
    final editedText = structured?['editedText'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$_agencyName Editoryal Denetim'),
        actions: [
          IconButton(
            tooltip: 'Kayıtlı Nihai Haberler',
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: _showSavedNewsDialog,
          ),
        ],
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
                    moduleType: 'editorial',
                    onChanged: (model) {
                      setState(() => _selectedModel = model);
                      ApiKeyStorage.saveModel('editorial', model);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Metin Giriş Kartı
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Denetlenecek Haber Metni',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.clear_all, size: 20),
                        onPressed: () => _newsTextController.clear(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newsTextController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Haber metnini buraya yapıştırın...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Denetle Butonu
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF003366),
            ),
            onPressed: _isChecking ? null : _checkEditorial,
            icon: _isChecking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.fact_check),
            label: Text(
              _isChecking ? 'Editoryal Denetim Yapılıyor...' : '🔍 Haberi Denetle ve Düzelt',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // SONUÇ BÖLÜMÜ
          if (_result != null)
            if (_result!.isSuccess) ...[
              if (_currentLoadedItem != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16, color: Color(0xFF003366)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yüklü Kayıt: ${_currentLoadedItem!.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003366)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        label: const Text('Yeni Kayıt Modu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        onPressed: () => setState(() => _currentLoadedItem = null),
                      ),
                    ],
                  ),
                ),

              // 1. ÖNCELİKLİ ANA KUTU: YAYINA HAZIR SAF NİHAİ HABER METNİ
              // SADECE BU METİN KOPYALANIR, WORD OLUR, SESLİ OKUNUR, KAYDEDİLİR VE PROMPTER'A GİDER!
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.teal.shade400, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified, color: Colors.teal, size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yayına Hazır Nihai Haber',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF003366)),
                                  ),
                                  Text(
                                    'Editoryal onaydan geçmiş saf haber metni',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Hızlı İşlem İkonları: Kopyala, Word İndir, Sesli Oku
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Nihai Haberi Kopyala',
                                icon: const Icon(Icons.copy, size: 19, color: Color(0xFF003366)),
                                onPressed: () => _copyText(editedText, 'Nihai Haber'),
                              ),
                              IconButton(
                                tooltip: 'Word (.docx) İndir',
                                icon: const Icon(Icons.download, size: 19, color: Color(0xFF003366)),
                                onPressed: () => _exportDocx(editedText, '${_agencyName.replaceAll(' ', '_')}_Nihai_Haber'),
                              ),
                              IconButton(
                                tooltip: _isSpeaking ? 'Sesli Okumayı Durdur' : 'Haberi Sesli Oku',
                                icon: Icon(
                                  _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                                  size: 22,
                                  color: _isSpeaking ? Colors.red : Colors.teal.shade700,
                                ),
                                onPressed: () => _toggleSpeech(editedText),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 18),

                      // Saf Haber Metni Gösterimi
                      SelectableRegion(
                        focusNode: FocusNode(),
                        selectionControls: materialTextSelectionControls,
                        child: MarkdownBody(
                          data: editedText.isNotEmpty ? editedText : '*Düzeltilmiş saf metin üretilemedi.*',
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF0F172A)),
                            h1: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                            h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF00A3E0)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // EYLEMLER: KAYDET / GÜNCELLE / SİL & TV-PROMPTER'A GÖNDER
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(_currentLoadedItem != null ? Icons.save_as : Icons.save, size: 18),
                            label: Text(_currentLoadedItem != null ? 'Haberi Güncelle' : 'Nihai Haberi Kaydet'),
                            onPressed: () => _saveOrUpdateNews(editedText, report),
                          ),
                          if (_currentLoadedItem != null)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Kaydı Sil'),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Kaydı Sil'),
                                    content: Text('"${_currentLoadedItem!.title}" kaydını silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await SavedContentService.deleteNews(_currentLoadedItem!.id);
                                  await _loadSavedNews();
                                  if (mounted) {
                                    setState(() {
                                      _currentLoadedItem = null;
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Kayıt silindi.')),
                                    );
                                  }
                                }
                              },
                            ),

                          // SADECE VE KESİNLİKLE EDİTORYALDEN ÇIKMIŞ SAF HABERİ TV & PROMPTER'A GÖNDERİR!
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final target = editedText.isNotEmpty ? editedText : _newsTextController.text;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TvNewsScreen(initialText: target),
                                ),
                              );
                            },
                            icon: const Icon(Icons.tv, size: 18),
                            label: const Text('📺 TV & Prompter\'a Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. FARKLI KUTU: EDİTORYAL DENETİM RAPORU & KARNE
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blueGrey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, color: Color(0xFF003366), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '📊 $_agencyName Denetim Raporu & İmla Karnesi',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Raporu Kopyala',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyText(report, 'Denetim Raporu'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 6),
                      MarkdownBody(
                        data: report.isNotEmpty ? report : _result!.text,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: const TextStyle(fontSize: 13, height: 1.5),
                          h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                          h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF00A3E0)),
                          h3: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. FARKLI KUTU: YAPILAN DEĞİŞİKLİKLER VE İYİLEŞTİRMELER
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note, color: Colors.orange, size: 22),
                              SizedBox(width: 8),
                              Text(
                                '✏️ Yapılan İyileştirmeler ve Düzeltmeler',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Maddeleri Kopyala',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyText(changelog, 'Değişiklik Maddeleri'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 6),
                      MarkdownBody(
                        data: changelog.isNotEmpty ? changelog : '*Değişiklik maddesi belirtilmedi.*',
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
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
                          _result!.errorMessage ?? 'Denetim başarısız oldu.',
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
