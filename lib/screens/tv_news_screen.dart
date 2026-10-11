import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';
import '../services/gemini_api_service.dart';
import '../services/saved_content_service.dart';
import '../widgets/model_selector_dropdown.dart';
import '../widgets/result_card.dart';

class TvNewsScreen extends StatefulWidget {
  final String? initialText;

  const TvNewsScreen({super.key, this.initialText});

  @override
  State<TvNewsScreen> createState() => _TvNewsScreenState();
}

class _TvNewsScreenState extends State<TvNewsScreen> {
  final _newsTextController = TextEditingController();
  bool _hasVideo = true; // Video/Görüntü opsiyonu (Var / Yok)
  bool _isPhonetic = true; // Fonetik format (Spiker & TTS)
  bool _isConverting = false;
  String _selectedModel = GeminiModelConfig.defaultTvModel;
  String _agencyName = ApiKeyStorage.defaultAgency;
  GeminiResponseResult? _result;

  // Prompter Kayıt Yönetimi (CRUD)
  SavedPrompterItem? _currentLoadedItem;
  List<SavedPrompterItem> _savedPrompterList = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _newsTextController.text = widget.initialText!;
    }
    _loadSettings();
    _loadSavedPrompters();
  }

  Future<void> _loadSettings() async {
    final model = await ApiKeyStorage.getModelForModule('tv');
    final agency = await ApiKeyStorage.getAgencyName();
    if (mounted) {
      setState(() {
        _selectedModel = model;
        _agencyName = agency;
      });
    }
  }

  Future<void> _loadSavedPrompters() async {
    final list = await SavedContentService.getSavedPrompters();
    if (mounted) {
      setState(() {
        _savedPrompterList = list;
      });
    }
  }

  @override
  void dispose() {
    _newsTextController.dispose();
    super.dispose();
  }

  String _extractKjTitle(String text) {
    for (final line in text.split('\n')) {
      if (line.trim().startsWith('KJ:')) {
        final raw = line.replaceFirst('KJ:', '').trim();
        final safe = raw.replaceAll(RegExp(r'[\\/*?:"<>|]'), '').replaceAll(' ', '_');
        if (safe.isNotEmpty) {
          return safe.length > 30 ? safe.substring(0, 30) : safe;
        }
      }
    }
    return '${_agencyName.replaceAll(' ', '_')}_TV_Bulteni';
  }

  // --- PROMPTER KAYDET & GÜNCELLE ---
  Future<void> _saveOrUpdatePrompter(String content) async {
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek bülten / prompter metni bulunamadı.')),
      );
      return;
    }

    String defaultTitle = _extractKjTitle(content);
    final titleController = TextEditingController(
      text: _currentLoadedItem != null ? _currentLoadedItem!.title : defaultTitle,
    );

    final isUpdating = _currentLoadedItem != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isUpdating ? 'Prompter Bültenini Güncelle' : 'Prompter Bültenini Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bülten / KJ Başlığı:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bülten başlığını girin',
              ),
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
        _currentLoadedItem!.updatedAt = DateTime.now();
        await SavedContentService.savePrompter(_currentLoadedItem!);
      } else {
        final newItem = SavedPrompterItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _currentLoadedItem = newItem;
        await SavedContentService.savePrompter(newItem);
      }
      await _loadSavedPrompters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? 'Prompter bülteni güncellendi!' : 'Prompter bülteni kaydedildi!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  // --- KAYITLI PROMPTERLAR LİSTESİ DİYALOĞU ---
  Future<void> _showSavedPromptersDialog() async {
    await _loadSavedPrompters();
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
                    Row(
                      children: [
                        const Icon(Icons.tv, color: Color(0xFF003366)),
                        const SizedBox(width: 8),
                        Text(
                          'Kayıtlı TV Bültenleri (${_savedPrompterList.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                if (_savedPrompterList.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Henüz kaydedilmiş bir TV bülteni veya prompter metni bulunmuyor.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _savedPrompterList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = _savedPrompterList[idx];
                        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.updatedAt);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00A3E0).withAlpha(30),
                            child: const Icon(Icons.live_tv, color: Color(0xFF003366)),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text('Son Güncelleme: $dateStr', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Bülteni Sil',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Bülteni Sil'),
                                      content: Text('"${item.title}" bültenini silmek istediğinize emin misiniz?'),
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
                                    await SavedContentService.deletePrompter(item.id);
                                    final updated = await SavedContentService.getSavedPrompters();
                                    setSheetState(() {
                                      _savedPrompterList = updated;
                                    });
                                    setState(() {
                                      _savedPrompterList = updated;
                                      if (_currentLoadedItem?.id == item.id) {
                                        _currentLoadedItem = null;
                                      }
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline, color: Color(0xFF003366), size: 22),
                                tooltip: 'Promptera Yükle',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _currentLoadedItem = item;
                                    _result = GeminiResponseResult(
                                      isSuccess: true,
                                      text: item.content,
                                      usedModel: _selectedModel,
                                    );
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${item.title}" yüklendi.'),
                                      backgroundColor: const Color(0xFF003366),
                                    ),
                                  );
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

  Future<void> _convertToTv() async {
    final text = _newsTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen dönüştürülecek haber metnini giriniz.')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
      _result = null;
      _currentLoadedItem = null;
    });

    final res = await GeminiApiService.convertToTvFormat(
      newsText: text,
      hasVideo: _hasVideo,
      isPhonetic: _isPhonetic,
      preferredModel: _selectedModel,
    );

    if (mounted) {
      setState(() {
        _isConverting = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_agencyName TV Formatı & Prompter'),
        actions: [
          IconButton(
            tooltip: 'Kayıtlı Prompterlar (${_savedPrompterList.length})',
            icon: Badge(
              label: Text('${_savedPrompterList.length}'),
              isLabelVisible: _savedPrompterList.isNotEmpty,
              child: const Icon(Icons.folder_special),
            ),
            onPressed: _showSavedPromptersDialog,
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
                    moduleType: 'tv',
                    onChanged: (model) => setState(() => _selectedModel = model),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Video / Görüntü & Fonetik Seçenekleri Kartı
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.video_camera_front, color: Color(0xFF003366), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Video & Fonetik Bülten Ayarları',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.videocam),
                        label: Text('Video / VTR Var'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.person),
                        label: Text('Sadece Spiker'),
                      ),
                    ],
                    selected: {_hasVideo},
                    onSelectionChanged: (set) {
                      setState(() {
                        _hasVideo = set.first;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🎙️ Spiker & TTS Fonetik Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sayılar harfle yazılır, kısaltmalar açılır ve nefes durakları (" / ") eklenir.', style: TextStyle(fontSize: 11)),
                    value: _isPhonetic,
                    activeTrackColor: const Color(0xFF00A3E0),
                    onChanged: (val) => setState(() => _isPhonetic = val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Haber Metni Girişi
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kısaltılacak & TV Formatına Dönüştürülecek Metin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newsTextController,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      hintText: 'Uzun haber metnini buraya yapıştırın. TV spikeri için KJ ve CAM etiketli kısa bülten oluşturulacaktır...',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dönüştür Butonu
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF003366),
            ),
            onPressed: _isConverting ? null : _convertToTv,
            icon: _isConverting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.tv),
            label: Text(
              _isConverting ? 'TV Formatına Dönüştürülüyor...' : '📺 TV Bülten Formatına Dönüştür',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // Sonuç Alanı + Kaydet / Güncelle / Sil
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
                      const Icon(Icons.live_tv, size: 16, color: Color(0xFF003366)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yüklü Bülten: ${_currentLoadedItem!.title}',
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

              ResultCard(
                title: '📺 $_agencyName TV Bülteni & Spiker Metni',
                content: _result!.text,
                modelUsed: _result!.usedModel,
                isMarkdown: false,
                showTeleprompter: true,
                defaultDocxTitle: _extractKjTitle(_result!.text),
              ),

              const SizedBox(height: 12),

              // CRUD Butonları: Kaydet, Güncelle, Sil
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(_currentLoadedItem != null ? Icons.save_as : Icons.save),
                        label: Text(_currentLoadedItem != null ? 'Bülteni Güncelle' : 'Bülteni Kaydet'),
                        onPressed: () => _saveOrUpdatePrompter(_result!.text),
                      ),
                      if (_currentLoadedItem != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Bu Bülteni Sil'),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Bülteni Sil'),
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
                              await SavedContentService.deletePrompter(_currentLoadedItem!.id);
                              await _loadSavedPrompters();
                              if (mounted) {
                                setState(() {
                                  _currentLoadedItem = null;
                                });
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Bülten silindi.')),
                                );
                              }
                            }
                          },
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
                          _result!.errorMessage ?? 'TV formatına dönüştürülemedi.',
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
