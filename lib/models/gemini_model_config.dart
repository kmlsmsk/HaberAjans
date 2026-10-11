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
  /// Yalnızca çalışan, güncel ve resmi Flash modelleri varsayılan olarak sunulur
  static const List<GeminiModelOption> defaultBuiltInModels = [
    GeminiModelOption(
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      description: 'En güncel, ultra hızlı ve hatasız çok modlu yapay zeka (Varsayılan & Önerilen)',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-2.0-flash',
      name: 'Gemini 2.0 Flash',
      description: 'Hızlı, dengeli ve kararlı yeni nesil üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-2.0-flash-lite',
      name: 'Gemini 2.0 Flash-Lite',
      description: 'Düşük gecikmeli, ultra hafif ve yüksek verimli Flash modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
  ];

  static const String defaultGlobalModel = 'gemini-2.5-flash';
  static const String defaultAudioModel = 'gemini-2.5-flash';
  static const String defaultNewsModel = 'gemini-2.5-flash';
  static const String defaultTvModel = 'gemini-2.5-flash';
  static const String defaultEditorialModel = 'gemini-2.5-flash';

  // Kullanımdan kalkan, desteklenmeyen veya uyumsuz modelleri güvenli Flash 2.5'e yönlendiren harita
  static const Map<String, String> legacyModelAliases = {
    'gemini-1.5-flash': 'gemini-2.5-flash',
    'gemini-1.5-pro': 'gemini-2.5-flash',
    'gemini-2.5-pro': 'gemini-2.5-flash',
    'gemini-pro': 'gemini-2.5-flash',
    'gemini-3.8-flash': 'gemini-2.5-flash',
    'gemini-3.8-live': 'gemini-2.5-flash',
    'gemini-3.8-live-extended-thinking': 'gemini-2.5-flash',
    'gemini-3-flash-preview': 'gemini-2.5-flash',
    'flash': 'gemini-2.5-flash',
    'pro': 'gemini-2.5-flash',
  };

  /// Model ID'sini temizler ve eski/geçersiz modelleri doğrudan varsayılan Flash 2.5'e yönlendirir
  static String sanitizeModel(String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) {
      return defaultGlobalModel;
    }
    final clean = modelId.replaceAll('models/', '').trim();
    final lower = clean.toLowerCase();

    // Eski/kullanımdan kalkmış alias'lar
    if (legacyModelAliases.containsKey(lower)) {
      return legacyModelAliases[lower]!;
    }

    // "pro" içeren eski modelleri varsayılana çek, ancak kullanıcı özel eklemişse koru
    if (lower == 'gemini-1.5-pro' || lower == 'gemini-2.5-pro' || lower == 'gemini-pro') {
      return defaultGlobalModel;
    }

    return clean;
  }

  /// Güvenilir Fallback zinciri (Sadece çalışan Flash modelleri)
  static List<String> getFallbackModels(String preferredModel) {
    final sanitized = sanitizeModel(preferredModel);
    final list = <String>[sanitized];
    const flashBackups = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
    ];
    for (final b in flashBackups) {
      if (!list.contains(b)) {
        list.add(b);
      }
    }
    return list;
  }
}
