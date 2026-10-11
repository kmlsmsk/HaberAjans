import 'package:flutter/material.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';
import '../services/gemini_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _rectorNameController = TextEditingController();
  final _cityNameController = TextEditingController();
  final _portalUrlController = TextEditingController();

  bool _obscureApiKey = true;
  bool _isValidating = false;
  bool _isFetchingModels = false;
  bool? _isKeyValid;
  String _validationMessage = '';

  String _globalModel = GeminiModelConfig.defaultGlobalModel;
  String _audioModel = GeminiModelConfig.defaultAudioModel;
  String _newsModel = GeminiModelConfig.defaultNewsModel;
  String _tvModel = GeminiModelConfig.defaultTvModel;
  String _editorialModel = GeminiModelConfig.defaultEditorialModel;

  List<GeminiModelOption> _models = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiKey = await ApiKeyStorage.getApiKey();
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();
    final cityName = await ApiKeyStorage.getCityName();
    final portalUrl = await ApiKeyStorage.getPortalUrl();
    final models = await ApiKeyStorage.getAllModels();

    final globalModel = await ApiKeyStorage.getModelForModule('global');
    final audioModel = await ApiKeyStorage.getModelForModule('audio');
    final newsModel = await ApiKeyStorage.getModelForModule('news');
    final tvModel = await ApiKeyStorage.getModelForModule('tv');
    final editorialModel = await ApiKeyStorage.getModelForModule('editorial');

    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _universityNameController.text = universityName;
        _agencyNameController.text = agencyName;
        _rectorNameController.text = rectorName;
        _cityNameController.text = cityName;
        _portalUrlController.text = portalUrl;
        _models = models;
        _globalModel = globalModel;
        _audioModel = audioModel;
        _newsModel = newsModel;
        _tvModel = tvModel;
        _editorialModel = editorialModel;
      });
    }
  }

  Future<void> _saveAll() async {
    await ApiKeyStorage.saveApiKey(_apiKeyController.text);
    await ApiKeyStorage.saveUniversityName(_universityNameController.text);
    await ApiKeyStorage.saveAgencyName(_agencyNameController.text);
    await ApiKeyStorage.saveRectorName(_rectorNameController.text);
    await ApiKeyStorage.saveCityName(_cityNameController.text);
    await ApiKeyStorage.savePortalUrl(_portalUrlController.text);

    await ApiKeyStorage.saveAllModuleModels(
      globalModel: _globalModel,
      audioModel: _audioModel,
      newsModel: _newsModel,
      tvModel: _tvModel,
      editorialModel: _editorialModel,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Tüm kurumsal parametreler ve ayarlar kaydedildi!'),
          ],
        ),
        backgroundColor: Color(0xFF003366),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isKeyValid = false;
        _validationMessage = 'Lütfen bir API anahtarı giriniz.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = 'Bağlantı test ediliyor...';
    });

    final isValid = await GeminiApiService.validateApiKey(key);

    if (!mounted) return;
    setState(() {
      _isValidating = false;
      _isKeyValid = isValid;
      _validationMessage = isValid
          ? 'API Anahtarı geçerli ve Google Gemini ile bağlantı kuruldu!'
          : 'API Anahtarı geçersiz veya yetkisiz. Lütfen kontrol ediniz.';
    });
  }

  Future<void> _fetchRemoteModels() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir API anahtarı girin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isFetchingModels = true;
    });

    final remoteNames = await GeminiApiService.fetchRemoteModels(key);

    if (!mounted) return;
    setState(() {
      _isFetchingModels = false;
    });

    if (remoteNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google hesabınızdan model listesi alınamadı.'), backgroundColor: Colors.red),
      );
      return;
    }

    int addedCount = 0;
    for (final name in remoteNames) {
      if (!_models.any((m) => m.id == name)) {
        final newModel = GeminiModelOption(
          id: name,
          name: name.replaceAll('-', ' ').toUpperCase(),
          description: 'Google API üzerinden otomatik eklendi',
          isCustom: true,
        );
        _models.add(newModel);
        await ApiKeyStorage.addOrUpdateModel(newModel);
        addedCount++;
      }
    }

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$addedCount yeni model listeye eklendi!'),
        backgroundColor: const Color(0xFF003366),
      ),
    );
  }

  void _showAddOrEditModelDialog([GeminiModelOption? existingModel]) {
    final isEditing = existingModel != null;
    final idController = TextEditingController(text: existingModel?.id ?? '');
    final nameController = TextEditingController(text: existingModel?.name ?? '');
    final descController = TextEditingController(text: existingModel?.description ?? '');
    bool isAudio = existingModel?.isAudioSupported ?? true;
    bool isVision = existingModel?.isVisionSupported ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.add_circle, color: const Color(0xFF003366)),
              const SizedBox(width: 8),
              Text(isEditing ? 'Modeli Düzenle' : 'Yeni Model Ekle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  enabled: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Model ID (Örn: gemini-2.5-flash)',
                    hintText: 'gemini-2.5-flash',
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Görünen Ad',
                    hintText: 'Gemini 2.5 Flash',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Not',
                    hintText: 'Hızlı ve güçlü temel model...',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ses Çözümleme Desteği', style: TextStyle(fontSize: 14)),
                  value: isAudio,
                  activeTrackColor: const Color(0xFF00A3E0),
                  onChanged: (val) => setDlgState(() => isAudio = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Görsel / Vision Desteği', style: TextStyle(fontSize: 14)),
                  value: isVision,
                  activeTrackColor: const Color(0xFF00A3E0),
                  onChanged: (val) => setDlgState(() => isVision = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = idController.text.trim();
                final name = nameController.text.trim();
                if (id.isEmpty) return;

                final updated = GeminiModelOption(
                  id: id,
                  name: name.isEmpty ? id : name,
                  description: descController.text.trim(),
                  isAudioSupported: isAudio,
                  isVisionSupported: isVision,
                  isCustom: true,
                );

                await ApiKeyStorage.addOrUpdateModel(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadSettings();
              },
              child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteModel(GeminiModelOption model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modeli Sil'),
        content: Text('${model.name} (${model.id}) modelini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await ApiKeyStorage.deleteModel(model.id);
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadSettings();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modelleri Sıfırla'),
        content: const Text('Tüm model listesi orijinal fabrika ayarlarına döndürülecek. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              await ApiKeyStorage.resetModelsToDefault();
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadSettings();
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(String label, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _models.any((m) => m.id == value) ? value : _models.first.id,
                  isExpanded: true,
                  items: _models.map((m) {
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Model Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Tümünü Kaydet',
            icon: const Icon(Icons.save),
            onPressed: _saveAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. API KEY KARTI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vpn_key, color: Color(0xFF003366)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Google Gemini API Anahtarı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Tüm yapay zeka modülleri bu anahtarı kullanır', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key (AIza...)',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isValidating ? null : _testApiKey,
                          icon: _isValidating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Bağlantıyı Test Et'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isFetchingModels ? null : _fetchRemoteModels,
                          icon: _isFetchingModels
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_download),
                          label: const Text('Modelleri Çek'),
                        ),
                      ),
                    ],
                  ),
                  if (_validationMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isKeyValid == true ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_isKeyValid == true ? Icons.check : Icons.error, color: _isKeyValid == true ? Colors.green : Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationMessage,
                              style: TextStyle(color: _isKeyValid == true ? Colors.green.shade900 : Colors.red.shade900, fontSize: 12),
                            ),
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

          // 2. DİNAMİK & ANONİM KURUMSAL AYARLAR KARTI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A3E0).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance, color: Color(0xFF003366)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kurumsal İsim ve Parametre Yönetimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Haber, TV ve Word çıktılarındaki kurum bilgileri', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _universityNameController,
                    decoration: const InputDecoration(
                      labelText: '🏛️ Üniversite / Kurum Adı',
                      hintText: 'ABC Üniversitesi',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _agencyNameController,
                    decoration: const InputDecoration(
                      labelText: '📰 Ajans / Haber Birimi Adı',
                      hintText: 'ABC Ajansı',
                      prefixIcon: Icon(Icons.newspaper_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rectorNameController,
                    decoration: const InputDecoration(
                      labelText: '👔 Rektör / Yönetici Adı & Ünvanı',
                      hintText: 'Prof. Dr. Adı Soyadı',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityNameController,
                    decoration: const InputDecoration(
                      labelText: '📍 Şehir / Mahreç',
                      hintText: 'İZMİR',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portalUrlController,
                    decoration: const InputDecoration(
                      labelText: '🌐 Haber Portalı / Web Adresi',
                      hintText: 'www.xxxajans.com',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. MODÜL BAZLI MODEL ATAMALARI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modül Model Tercihleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Her modül için en uygun yapay zeka modelini atayabilirsiniz', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildDropdownItem('Genel Model:', _globalModel, (val) => setState(() => _globalModel = val!)),
                  _buildDropdownItem('🎙️ Ses Çözümleme:', _audioModel, (val) => setState(() => _audioModel = val!)),
                  _buildDropdownItem('📰 Haber Yazarı:', _newsModel, (val) => setState(() => _newsModel = val!)),
                  _buildDropdownItem('📺 TV Haber / Bülten:', _tvModel, (val) => setState(() => _tvModel = val!)),
                  _buildDropdownItem('🔍 Editoryal Denetim:', _editorialModel, (val) => setState(() => _editorialModel = val!)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. MODEL LİSTESİ YÖNETİMİ (CRUD)
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kayıtlı Gemini Modelleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Modelleri ekleyin, düzenleyin veya silin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Yeni Model Ekle',
                        icon: const Icon(Icons.add_circle, color: Color(0xFF003366), size: 28),
                        onPressed: () => _showAddOrEditModelDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _models.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = _models[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: m.isCustom ? Colors.orange.shade100 : const Color(0xFF00A3E0).withAlpha(30),
                          child: Icon(
                            m.isCustom ? Icons.extension : Icons.smart_toy,
                            color: m.isCustom ? Colors.orange.shade800 : const Color(0xFF003366),
                            size: 20,
                          ),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${m.id}\n${m.description}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        isThreeLine: m.description.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                              onPressed: () => _showAddOrEditModelDialog(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteModel(m),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _confirmResetDefaults,
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Varsayılan Modellere Sıfırla'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. GELİŞTİRİCİ & İMZA KARTI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF003366), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geliştiren',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Dr. Kemal ŞİMŞEK',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                        ),
                        Text(
                          'Bilgisayar Mühendisi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00A3E0), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Kaydet Butonu
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF003366),
            ),
            onPressed: _saveAll,
            icon: const Icon(Icons.check_circle),
            label: const Text('Tüm Ayarları Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
