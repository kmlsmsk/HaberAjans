import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/gemini_model_config.dart';
import 'api_key_storage.dart';

class GeminiResponseResult {
  final bool isSuccess;
  final String text;
  final String usedModel;
  final String? errorMessage;
  final Map<String, String>? structuredSections;

  GeminiResponseResult({
    required this.isSuccess,
    required this.text,
    required this.usedModel,
    this.errorMessage,
    this.structuredSections,
  });
}

class GeminiApiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// API Anahtarını doğrular
  static Future<bool> validateApiKey(String apiKey) async {
    try {
      final url = Uri.parse('$_baseUrl/models?key=${apiKey.trim()}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Google Hesabındaki kullanılabilir modelleri listeler
  static Future<List<String>> fetchRemoteModels(String apiKey) async {
    try {
      final url = Uri.parse('$_baseUrl/models?key=${apiKey.trim()}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List?)
            ?.map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .where((name) => name.contains('gemini'))
            .toList();
        return models ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// 1. SES ÇÖZÜMLEME (Audio Transcription)
  static Future<GeminiResponseResult> transcribeAudio({
    required Uint8List audioBytes,
    required String mimeType,
    String? preferredModel,
  }) async {
    final apiKey = await ApiKeyStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponseResult(
        isSuccess: false,
        text: '',
        usedModel: '',
        errorMessage: 'Lütfen Ayarlar bölümünden geçerli bir Gemini API Anahtarı giriniz.',
      );
    }

    final modelToUse = preferredModel ?? await ApiKeyStorage.getModelForModule('audio');

    const systemPrompt = """Sen bir Türkçe Ses Çözümleme ve Deşifre Uzmanısın.
Görevin, sana verilen ses kaydını dikkatlice dinleyerek en yüksek doğrulukla Türkçe metne çevirmektir.
Kurallar:
1. Sesi tam ve doğru bir şekilde Türkçe metne dök.
2. Metindeki bariz dil bilgisi, harf ve yazım hatalarını düzelt, akıcılığı sağla.
3. SADECE nihai, iyileştirilmiş Türkçe metni ver.
4. Başka hiçbir açıklama, giriş, selamlama veya sonuç cümlesi ekleme.
5. Metni mantıksal paragraflara ayır.""";

    final base64Audio = base64Encode(audioBytes);

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Audio,
              }
            },
            {
              'text': 'Lütfen bu ses kaydını yukarıdaki kurallara göre harfiyen çözümle ve mantıksal paragraflar halinde yaz.'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
      }
    };

    return await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
    );
  }

  /// 2. HABER YAZMA (Kurumsal Basın Bülteni Yazarı)
  static Future<GeminiResponseResult> generateNews({
    required String rawText,
    String? referenceUrl,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? preferredModel,
  }) async {
    final apiKey = await ApiKeyStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponseResult(
        isSuccess: false,
        text: '',
        usedModel: '',
        errorMessage: 'Lütfen Ayarlar bölümünden geçerli bir Gemini API Anahtarı giriniz.',
      );
    }

    final modelToUse = preferredModel ?? await ApiKeyStorage.getModelForModule('news');
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();
    final cityName = (await ApiKeyStorage.getCityName()).toUpperCase();
    final portalUrl = await ApiKeyStorage.getPortalUrl();

    final prompt = """
Sen $universityName $agencyName ($portalUrl) Haber Merkezi'nin kıdemli başyazarı ve haber editörüsün.
Görevin, sana sunulan ham notları, etkinlik bilgilerini ve (varsa) görseli kullanarak $universityName ve $agencyName'ın resmi ve saygın kurumsal yayın çizgisine tam uyumlu, kusursuz bir haber metni yazmaktır.

${agencyName.toUpperCase()} KURUMSAL HABER FORMATI VE YAZIM STANDARTLARI:
1. Haber Mimarisi (Ters Piramit & 5N1K Kuralı):
   - Başlık: '# ' ile başlayan, büyük ve kurumsal haber başlığı. (Örn: # $universityName'nden Bilimsel Atılım)
   - Spot (Özet): '**' ile kalınlaştırılmış, haberin ana fikrini ve 5N1K unsurlarını özetleyen 1-2 cümlelik vurucu spot.
   - Mahreç ve Giriş: Haber gövdesinin ilk paragrafı MUTLAKA "**$cityName ($agencyName) -** " ifadesiyle başlamalıdır. Giriş cümlesinde etkinliğin nerede, ne zaman, kimlerin katılımıyla gerçekleştiği net aktarılmalıdır.
   - Rektör / Yetkili Görüşü: Giriş paragrafını takiben, $universityName Rektörü $rectorName'nın vizyoner açıklamalarına ve demeçlerine yer ver. Demeci tırnak içinde ("...") belirt ve cümlenin sonunu "... dedi", "... ifadelerini kullandı" veya "... şeklinde konuştu" ile bağla.
   - Ara Başlıklar: Konu akışını düzenleyen '## ' seviyesinde anlamlı ve kurumsal ara başlıklar kullan.
   - İçerik Vurguları: $universityName'nin araştırma üniversitesi misyonu, TÜBİTAK/uluslararası projeleri, öğrenci odaklı yaklaşımı ve topluma hizmet ilkelerini kurumsal dille vurgula.
   - Etiketler: En sonda '### Etiketler:' başlığı altında 4-6 adet hashtag ekle.
2. Dil ve Üslup:
   - Tarafsız, güvenilir, saygın, akıcı ve editoryal ajans dili.
   - Cümleler düşük olmamalı, TDK kurallarına tam uyumlu olmalıdır.
   - Asla modelin kendi sohbet ifadelerini ekleme. Yalnızca doğrudan haber metnini Markdown olarak üret.

Girdi Bilgileri:
Ham Metin / Etkinlik Notları: $rawText
Referans / Kaynak Bağlantı: ${referenceUrl?.isNotEmpty == true ? referenceUrl : "Belirtilmedi"}
""";

    final parts = <Map<String, dynamic>>[];
    parts.add({'text': prompt});

    if (imageBytes != null && imageMimeType != null) {
      parts.add({
        'inline_data': {
          'mime_type': imageMimeType,
          'data': base64Encode(imageBytes),
        }
      });
    }

    final payload = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.65,
      }
    };

    return await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
    );
  }

  /// 3. TV HABER FORMATI (TV News Shortener & Teleprompter)
  static Future<GeminiResponseResult> convertToTvFormat({
    required String newsText,
    required bool hasVideo,
    bool isPhonetic = false,
    String? preferredModel,
  }) async {
    final apiKey = await ApiKeyStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponseResult(
        isSuccess: false,
        text: '',
        usedModel: '',
        errorMessage: 'Lütfen Ayarlar bölümünden geçerli bir Gemini API Anahtarı giriniz.',
      );
    }

    final modelToUse = preferredModel ?? await ApiKeyStorage.getModelForModule('tv');
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();

    final phoneticRules = isPhonetic
        ? """
ÖZEL SPİKER SESLENDİRME & FONETİK KURALLARI:
- Metni stüdyo spikerinin canlı yayında takılmadan okuyabilmesi ve Web Seslendirme (TTS) motorunun doğru telaffuz edebilmesi için fonetikleştir.
- Sayıları, yılları ve tarihleri mutlaka okunuşlarıyla yaz (Örn: "2026 yılında" yerine "iki bin yirmi altı yılında", "150 öğrenci" yerine "yüz elli öğrenci").
- Kısaltmaların telaffuzunu açıkça yaz (Örn: "TÜBİTAK" -> "Tübitak", "AB" -> "Avrupa Birliği").
- Spikerin nefes alacağı ve duraklayacağı yerlere eğik çizgi (" / ") işareti koy.
"""
        : "";

    final videoInstruction = hasVideo
        ? """
Habere GÖRÜNTÜ / VTR / RÖPORTAJ MEVCUTTUR.
Biçimlendirme Kuralları:
1. KJ: Kısa, vurucu ve haberin özünü veren alt bant başlığı. (İlk satır 'KJ: ...' olmalıdır. Örn: KJ: $universityName'nde Büyük Başarı)
2. CAM: Stüdyo spikerinin kameraya bakarak okuyacağı, izleyiciyi habere bağlayan 1-2 cümlelik dinamik giriş.
3. SES: Görüntü (VTR) üzerine seslendirilecek 1-2 cümlelik dış ses metni.
4. Video / Röportaj İbreleri: Haberdeki önemli kişilerin konuşma geçişleri (Örn: $rectorName Video).
5. SES: VTR devamı dış ses kapanış cümlesi.
"""
        : """
Habere GÖRÜNTÜ / VİDEO / VTR BULUNMAMAKTADIR. (SADECE STÜDYO SPİKERİ OKUYACAK)
Biçimlendirme Kuralları:
1. KJ: Kısa, dikkat çekici alt yazı başlığı. (İlk satır 'KJ: ...' olmalıdır)
2. CAM: Stüdyo spikerinin doğrudan kameraya bakarak haberi baştan sona özetleyeceği, akıcı, net ve vurucu bülten metni (3-4 kısa ve net cümle).
3. Kesinlikle VTR, Video, Röportaj, SES gibi var olmayan görüntü ibreleri EKLEME.
""";

    final prompt = """
Sen $universityName $agencyName TV Haber Masası'nın kıdemli bülten koordinatörü ve spiker editörüsün.
Sana verilen haber metnini televizyon haber bültenine uygun olarak **oldukça kısa, öz, vurucu ve net** bir şekilde yeniden yazmalısın.

$videoInstruction
$phoneticRules

ÖNEMLİ YAZIM KURALLARI:
- **ASLA markdown kalınlaştırma (**) veya yıldız işaretleri kullanma**. Örneğin CAM: veya KJ: gibi ifadelerde yıldız (**) asla kullanma.
- Çıktıyı tamamen temiz, düz metin (plain text) olarak üret.

Haber Metni:
---
$newsText
---
""";

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      }
    };

    return await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
      cleanMarkdownStars: true,
    );
  }

  /// 4. DİL, ÜSLUP & EDİTORYAL DENETİM (Editorial Checker)
  static Future<GeminiResponseResult> checkEditorialAndStyle({
    required String newsText,
    String? preferredModel,
  }) async {
    final apiKey = await ApiKeyStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponseResult(
        isSuccess: false,
        text: '',
        usedModel: '',
        errorMessage: 'Lütfen Ayarlar bölümünden geçerli bir Gemini API Anahtarı giriniz.',
      );
    }

    final modelToUse = preferredModel ?? await ApiKeyStorage.getModelForModule('editorial');
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();

    final prompt = """
Sen $universityName $agencyName Yayın Denetleme Kurulu Başkanı ve Baş Editörüsün.
Sana verilen haber metnini titizlikle incele ve 3 ana bölüme ayırarak değerlendir.

Aşağıdaki ETİKETLERİ VE BÖLÜM YAPISINI AYRI AYRI KULLANARAK YANIT VER:

=== RAPOR_BASLANGIC ===
# 📊 $agencyName Editoryal Değerlendirme Raporu

### 🎯 Genel Editoryal Puan: [100 üzerinden puan]/100
### 📋 5N1K Kontrol Karnesi
- **Ne?**: [Açıklama]
- **Kim?**: [Açıklama]
- **Nerede?**: [Açıklama]
- **Ne Zaman?**: [Açıklama]
- **Nasıl?**: [Açıklama]
- **Neden?**: [Açıklama]

### 🔍 TDK İmla ve Kurumsal Dil Denetimi
- İmla & Noktalama Durumu: [Değerlendirme]
- $agencyName Format Uyumu: [Mahreç girişi, Rektör $rectorName demeci ve tırnak alıntıları uyumu]
=== RAPOR_BITIS ===

=== DEGISIKLIKLER_BASLANGIC ===
### ✏️ Yapılan Düzeltmeler ve İyileştirme Maddeleri:
1. [Düzeltme 1]
2. [Düzeltme 2]
3. [Düzeltme 3]
=== DEGISIKLIKLER_BITIS ===

=== DUZELTILMIS_METIN_BASLANGIC ===
[Buraya haberin başlığı (# Başlık), spotu (**Spot**) ve $agencyName standartlarına göre sıfır hatayla yeniden yazılmış, kusursuz ve yayınlanmaya hazır nihai haber metnini yerleştir.]
=== DUZELTILMIS_METIN_BITIS ===

İncelenecek Haber Metni:
---
$newsText
---
""";

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
      }
    };

    final result = await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
    );

    if (result.isSuccess) {
      final fullText = result.text;
      final sections = _extractEditorialSections(fullText);
      return GeminiResponseResult(
        isSuccess: true,
        text: fullText,
        usedModel: result.usedModel,
        structuredSections: sections,
      );
    }

    return result;
  }

  static Map<String, String> _extractEditorialSections(String raw) {
    String report = '';
    String changelog = '';
    String editedText = '';

    final reportMatch = RegExp(r'=== RAPOR_BASLANGIC ===([\s\S]*?)=== RAPOR_BITIS ===').firstMatch(raw);
    if (reportMatch != null) {
      report = reportMatch.group(1)?.trim() ?? '';
    }

    final changeMatch = RegExp(r'=== DEGISIKLIKLER_BASLANGIC ===([\s\S]*?)=== DEGISIKLIKLER_BITIS ===').firstMatch(raw);
    if (changeMatch != null) {
      changelog = changeMatch.group(1)?.trim() ?? '';
    }

    final editedMatch = RegExp(r'=== DUZELTILMIS_METIN_BASLANGIC ===([\s\S]*?)=== DUZELTILMIS_METIN_BITIS ===').firstMatch(raw);
    if (editedMatch != null) {
      editedText = editedMatch.group(1)?.trim() ?? '';
    }

    // Fallback if tags were omitted
    if (report.isEmpty && editedText.isEmpty) {
      report = raw;
      editedText = raw;
    } else if (editedText.isEmpty) {
      editedText = raw;
    }

    return {
      'report': report,
      'changelog': changelog,
      'editedText': editedText,
    };
  }

  /// Fallback mekanizmalı API Çağrısı
  static Future<GeminiResponseResult> _executeWithFallback({
    required String apiKey,
    required String primaryModel,
    required Map<String, dynamic> payload,
    bool cleanMarkdownStars = false,
  }) async {
    final sanitizedPrimary = GeminiModelConfig.sanitizeModel(primaryModel);
    final modelsToTry = GeminiModelConfig.getFallbackModels(sanitizedPrimary);
    String lastError = 'Bilinmeyen bir hata oluştu.';

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 90));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String text = parts[0]['text'] ?? '';
              if (cleanMarkdownStars) {
                text = text.replaceAll('**', '').replaceAll('*', '');
              }
              return GeminiResponseResult(
                isSuccess: true,
                text: text.trim(),
                usedModel: model,
              );
            }
          }
          lastError = '$model: Modelden geçerli bir metin yanıtı alınamadı.';
        } else {
          final errBody = response.body;
          try {
            final errJson = jsonDecode(errBody);
            final msg = errJson['error']?['message'] ?? 'HTTP ${response.statusCode}';
            lastError = '$model: $msg';
          } catch (_) {
            lastError = '$model: HTTP ${response.statusCode} - $errBody';
          }
          // Sonraki fallback modeline devam et
        }
      } catch (e) {
        lastError = '$model: ${e.toString()}';
      }
    }

    return GeminiResponseResult(
      isSuccess: false,
      text: '',
      usedModel: sanitizedPrimary,
      errorMessage: 'Gemini API çağrısı başarısız oldu:\n$lastError',
    );
  }
}
