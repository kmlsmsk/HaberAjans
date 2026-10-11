class GeminiModelOption {
  final String id;
  final String name;
  final String description;
  final bool isAudioSupported;
  final bool isVisionSupported;
  final bool isCustom;

  const GeminiModelOption({
    required this.id,
    required this.name,
    required this.description,
    this.isAudioSupported = true,
    this.isVisionSupported = true,
    this.isCustom = false,
  });

  GeminiModelOption copyWith({
    String? id,
    String? name,
    String? description,
    bool? isAudioSupported,
    bool? isVisionSupported,
    bool? isCustom,
  }) {
    return GeminiModelOption(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isAudioSupported: isAudioSupported ?? this.isAudioSupported,
      isVisionSupported: isVisionSupported ?? this.isVisionSupported,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isAudioSupported': isAudioSupported,
      'isVisionSupported': isVisionSupported,
      'isCustom': isCustom,
    };
  }

  factory GeminiModelOption.fromJson(Map<String, dynamic> json) {
    return GeminiModelOption(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      isAudioSupported: json['isAudioSupported'] as bool? ?? true,
      isVisionSupported: json['isVisionSupported'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class GeminiModelConfig {
  /// Kullanıcının talep ettiği tüm güncel modeller (Gemini 2.5, 3.x, Nano Banana, Transcribe, Live, TTS vb.)
  static const List<GeminiModelOption> defaultBuiltInModels = [
    // 1. VARSAYILAN & ÖNERİLEN MODEL
    GeminiModelOption(
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      description: 'Düşük gecikme süresi, yüksek hacimli ve akıl yürütme için en iyi fiyat-performans modeli (Varsayılan & Önerilen)',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    // 2. GEMINI 2.5 AİLESİ
    GeminiModelOption(
      id: 'gemini-2.5-flash-lite',
      name: 'Gemini 2.5 Flash-Lite',
      description: '2.5 ailesindeki en hızlı ve en uygun fiyatlı çok formatlı model',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-2.5-flash-native-audio-preview-12-2025',
      name: 'Gemini 2.5 Flash Live',
      description: 'Bir saniyeden kısa sürede doğal ses akışı sağlayan, gerçek zamanlı optimize model',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-2.5-flash-preview-tts',
      name: 'Gemini 2.5 Flash TTS',
      description: 'Stil ve hız üzerinde hassas kontrol sağlayan metin okuma ses üretimi',
      isAudioSupported: true,
      isVisionSupported: false,
    ),
    GeminiModelOption(
      id: 'gemini-2.5-flash-image',
      name: 'Nano Banana (2.5 Flash Image)',
      description: 'Hızlı ve yaratıcı iş akışları için son teknoloji yerel görüntü üretme ve düzenleme',
      isAudioSupported: false,
      isVisionSupported: true,
    ),

    // 3. GEMINI 3.8 AİLESİ
    GeminiModelOption(
      id: 'gemini-3.8-flash',
      name: 'Gemini 3.8 Flash',
      description: 'Son teknoloji yüksek hızlı akıl yürütme ve genel üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.8-live',
      name: 'Gemini 3.8 Live',
      description: 'Gerçek zamanlı iki yönlü canlı etkileşim ve çok modlu oturum modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.8-live-extended-thinking',
      name: 'Gemini 3.8 Live Extended Thinking',
      description: 'Genişletilmiş derin düşünme ve karmaşık analiz yetenekli canlı model',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.8-flash-tts',
      name: 'Gemini 3.8 Flash TTS',
      description: 'Yüksek kaliteli, akıcı ve doğal ses sentezleme modeli',
      isAudioSupported: true,
      isVisionSupported: false,
    ),
    GeminiModelOption(
      id: 'gemini-3.8-flash-lite-tts',
      name: 'Gemini 3.8 Flash-Lite TTS',
      description: 'Düşük gecikmeli ve ultra hafif metin seslendirme modeli',
      isAudioSupported: true,
      isVisionSupported: false,
    ),

    // 4. GEMINI 3.6 & 3.5 MODELLERİ
    GeminiModelOption(
      id: 'gemini-3.6-flash',
      name: 'Gemini 3.6 Flash',
      description: 'Dengeli, kararlı ve yeni nesil çok modlu Flash modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.5-flash-lite',
      name: 'Gemini 3.5 Flash-Lite',
      description: 'Ultra hafif, yüksek hacimli ve verimli yeni nesil üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.5-transcribe',
      name: 'Gemini 3.5 Transcribe',
      description: 'Ses çözümleme ve röportaj deşifresi için optimize edilmiş uzman model',
      isAudioSupported: true,
      isVisionSupported: false,
    ),
    GeminiModelOption(
      id: 'gemini-3.5-transcribe-live',
      name: 'Gemini 3.5 Transcribe Live',
      description: 'Gerçek zamanlı kesintisiz canlı ses deşifresi ve metne dönüştürme',
      isAudioSupported: true,
      isVisionSupported: false,
    ),
    GeminiModelOption(
      id: 'gemini-3.5-live-translate-preview',
      name: 'Gemini 3.5 Live Translate',
      description: 'Eşzamanlı canlı çeviri, diller arası aktarım ve haber lokalizasyonu',
      isAudioSupported: true,
      isVisionSupported: false,
    ),

    // 5. GEMINI 3.1 & 3.0 MODELLERİ
    GeminiModelOption(
      id: 'gemini-3.1-flash-lite',
      name: 'Gemini 3.1 Flash-Lite',
      description: 'Düşük kaynak tüketimli hızlı üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.1-flash-live-preview',
      name: 'Gemini 3.1 Flash Live',
      description: 'Canlı çok modlu etkileşim önizleme modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.1-flash-tts-preview',
      name: 'Gemini 3.1 Flash TTS',
      description: 'Hızlı seslendirme ve konuşma önizleme modeli',
      isAudioSupported: true,
      isVisionSupported: false,
    ),
    GeminiModelOption(
      id: 'gemini-3-flash-preview',
      name: 'Gemini 3 Flash Preview',
      description: 'Gemini 3 nesli önizleme Flash modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.1-pro-preview',
      name: 'Gemini 3.1 Pro Preview',
      description: 'Gelişmiş mantıksal akıl yürütme ve derin editoryal analiz modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-omni-1.1-flash',
      name: 'Gemini Omni Flash (1.1)',
      description: 'Çok formatlı omni mimarisi ile ses, metin ve görsel entegrasyonu',
      isAudioSupported: true,
      isVisionSupported: true,
    ),

    // 6. NANO BANANA GÖRSEL & MULTIMODAL AİLESİ
    GeminiModelOption(
      id: 'gemini-nano-banana-2.1',
      name: 'Nano Banana 2.1',
      description: 'Kompakt, verimli yerel multimodal ve yaratıcı içerik modeli',
      isAudioSupported: false,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.1-flash-image',
      name: 'Nano Banana 2 (3.1 Flash Image)',
      description: 'Hızlı görsel üretme, düzenleme ve görsel anlama modeli',
      isAudioSupported: false,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3.1-flash-lite-image',
      name: 'Nano Banana 2 Lite (3.1 Lite Image)',
      description: 'Hafif ve hızlı görsel işleme modeli',
      isAudioSupported: false,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-3-pro-image',
      name: 'Nano Banana Pro (3 Pro Image)',
      description: 'Profesyonel düzeyde yüksek kaliteli görüntü analizi ve üretimi',
      isAudioSupported: false,
      isVisionSupported: true,
    ),

    // 7. GEMINI 2.0 FLASH (Kararlı temel)
    GeminiModelOption(
      id: 'gemini-2.0-flash',
      name: 'Gemini 2.0 Flash',
      description: 'Hızlı, dengeli ve kararlı üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
  ];

  static const String defaultGlobalModel = 'gemini-2.5-flash';
  static const String defaultAudioModel = 'gemini-2.5-flash';
  static const String defaultNewsModel = 'gemini-2.5-flash';
  static const String defaultTvModel = 'gemini-2.5-flash';
  static const String defaultEditorialModel = 'gemini-2.5-flash';

  // Yalnızca kullanımdan kalkan eski sürümleri güvenli varsayılan modele yönlendiren harita
  static const Map<String, String> legacyModelAliases = {
    'gemini-1.5-flash': 'gemini-2.5-flash',
    'gemini-1.5-pro': 'gemini-2.5-flash',
    'gemini-pro': 'gemini-2.5-flash',
    'flash': 'gemini-2.5-flash',
  };

  /// Model ID'sini temizler. Eski kullanımdan kalkmış 1.5 modellerini varsayılan Flash 2.5'e taşır,
  /// kullanıcının seçtiği 2.5, 3.x, Nano Banana ve özel modelleri olduğu gibi korur.
  static String sanitizeModel(String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) {
      return defaultGlobalModel;
    }
    final clean = modelId.replaceAll('models/', '').trim();
    final lower = clean.toLowerCase();

    if (legacyModelAliases.containsKey(lower)) {
      return legacyModelAliases[lower]!;
    }

    if (lower == 'gemini-1.5-pro' || lower == 'gemini-pro') {
      return defaultGlobalModel;
    }

    return clean;
  }

  /// Güvenilir Fallback zinciri
  static List<String> getFallbackModels(String preferredModel) {
    final sanitized = sanitizeModel(preferredModel);
    final list = <String>[sanitized];
    const generalBackups = [
      'gemini-2.5-flash',
      'gemini-3.8-flash',
      'gemini-3.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-2.5-flash-lite',
    ];
    for (final b in generalBackups) {
      if (!list.contains(b)) {
        list.add(b);
      }
    }
    return list;
  }
}
