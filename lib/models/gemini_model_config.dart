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
  static const List<GeminiModelOption> defaultBuiltInModels = [
    GeminiModelOption(
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      description: 'En güncel, ultra hızlı, çok modlu haber işleme ve editoryal denetim (Varsayılan & Önerilen)',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-2.0-flash',
      name: 'Gemini 2.0 Flash',
      description: 'Hızlı ve kararlı yeni nesil üretim modeli',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-1.5-flash',
      name: 'Gemini 1.5 Flash',
      description: 'Yüksek kararlılık, güvenilir ses çözümleme ve geniş bağlam',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
    GeminiModelOption(
      id: 'gemini-1.5-pro',
      name: 'Gemini 1.5 Pro',
      description: 'Geniş bağlam pencereli profesyonel analitik model',
      isAudioSupported: true,
      isVisionSupported: true,
    ),
  ];

  static const String defaultGlobalModel = 'gemini-2.5-flash';
  static const String defaultAudioModel = 'gemini-2.5-flash';
  static const String defaultNewsModel = 'gemini-2.5-flash';
  static const String defaultTvModel = 'gemini-2.5-flash';
  static const String defaultEditorialModel = 'gemini-2.5-flash';

  // Kullanımdan kalkan veya uyumsuz model adlarını güvenli modellere eşleyen sözlük
  static const Map<String, String> modelAliases = {
    'gemini-2.5-pro': 'gemini-2.5-flash',
    'gemini-3.8-flash': 'gemini-2.5-flash',
    'gemini-3.8-live': 'gemini-2.5-flash',
    'gemini-3.8-live-extended-thinking': 'gemini-2.5-flash',
    'gemini-3-flash-preview': 'gemini-2.5-flash',
    'gemini-pro': 'gemini-2.5-flash',
    'flash': 'gemini-2.5-flash',
    'pro': 'gemini-2.5-flash',
  };

  /// Model ID'sini temizler ve geçerli stabil modele yönlendirir
  static String sanitizeModel(String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) {
      return defaultGlobalModel;
    }
    final clean = modelId.replaceAll('models/', '').trim();
    return modelAliases[clean] ?? clean;
  }

  /// Güvenilir Fallback zinciri
  static List<String> getFallbackModels(String preferredModel) {
    final sanitized = sanitizeModel(preferredModel);
    final list = <String>[sanitized];
    final backups = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];
    for (final b in backups) {
      if (!list.contains(b)) {
        list.add(b);
      }
    }
    return list;
  }
}
