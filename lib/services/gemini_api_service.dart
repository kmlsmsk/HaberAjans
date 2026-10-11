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
            .where((name) =>
                name.contains('gemini') &&
                !name.contains('1.5'))
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

    final rawModel = preferredModel ?? await ApiKeyStorage.getModelForModule('audio');
    final modelToUse = GeminiModelConfig.sanitizeModel(rawModel);

    const systemPrompt = """Sen bir Türkçe Ses Çözümleme ve Deşifre Uzmanısın.
Görevin, sana verilen ses kaydını dikkatlice dinleyerek bütün metni net ve anlaşılır bir biçimde, düzgün bir dil ve üslup ile Türkçe yazıya dönüştürmektir.

KESİN KURALLAR:
1. Bütün metni net, açık, anlaşılır ve eksiksiz olarak Türkçe metne dök.
2. Düzgün bir dil, üslup ve TDK imla akıcılığı sağla.
3. KESİNLİKLE KELİME EKLEME VE YORUM EKLEME. Konuşmada geçmeyen hiçbir ifadeyi, kişisel fikri veya yorumu metne dahil etme. Aslına %100 sadık kal.
4. SADECE çözümlenmiş saf metni ver. Giriş cümlesi, selamlama, kapanış, başlık açıklaması veya not EKLEME.
5. Konuşma akışına göre metni mantıksal paragraflara ayır.""";

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
              'text': 'Lütfen bu ses kaydındaki konuşmayı kelime eklemeden, yorum katmadan, net ve anlaşılır düzgün bir Türkçe ile çözümle.'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
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

    final rawModel = preferredModel ?? await ApiKeyStorage.getModelForModule('news');
    final modelToUse = GeminiModelConfig.sanitizeModel(rawModel);
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();
    final cityName = (await ApiKeyStorage.getCityName()).toUpperCase();
    final portalUrl = await ApiKeyStorage.getPortalUrl();

    final prompt = """
Sen $universityName $agencyName ($portalUrl) Haber Merkezi'nin kıdemli başyazarı ve kurumsal haber editörüsün.
Görevin, sana sunulan ham notları kurumsal haber ajansı ilkelerine tam uyumlu, saygın ve kusursuz bir basın bültenine dönüştürmektir.

KURUMSAL HABER AJANSI İLKELERİ VE YAZIM STANDARTLARI:
1. Kurumsal İlkeler & Üslup:
   - Kurumsal haber ajansı ilkelerini (tarafsızlık, doğruluk, kamu yararı, 5N1K ve ters piramit kuralı) daima göz önünde bulundur.
   - ABARTI VE FAZLA SÜSLÜ CÜMLELERDEN KESİNLİKLE UZAK DUR. Ağdalı sıfatlar, abartılı övgüler veya reklam dili yerine sade, net, nesnel, güvenilir ve saygın bir ajans dili kullan.
   - TDK kurallarına tam uyumlu olmalı, anlatım bozukluğu barındırmamalıdır.

2. Haber Mimarisi (Ters Piramit Formatı):
   - Başlık: '# ' ile başlayan, büyük, kurumsal, abartısız ve bilgilendirici başlık. (Örn: # $universityName'nde Yeni Akademik Yıl Başladı)
   - Spot (Özet): '**' ile kalınlaştırılmış, haberin temel özünü aktaran 1-2 cümlelik net spot.
   - Mahreç ve Giriş: İlk paragraf MUTLAKA "**$cityName ($agencyName) -** " ifadesiyle başlamalıdır. Giriş cümlesinde 5N1K unsurları (ne, nerede, ne zaman, kim, nasıl, neden) net şekilde yer almalıdır.
   - Rektör / Yetkili Görüşü: $universityName Rektörü $rectorName'nın kurumsal açıklamalarına yer ver. Demeci tırnak içinde ("...") belirt ve sonunu "... dedi" veya "... ifadelerini kullandı" ile bağla.
   - Ara Başlıklar: Akışı düzenleyen '## ' seviyesinde kurumsal ara başlıklar kullan.
   - Etiketler: En sonda '### Etiketler:' altında 4-6 adet kurumsal hashtag ekle.
   - Yalnızca haber metnini Markdown olarak üret, sohbet cümlesi ekleme.

Girdi Bilgileri:
Ham Notlar: $rawText
Kaynak Bağlantı: ${referenceUrl?.isNotEmpty == true ? referenceUrl : "Belirtilmedi"}
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
        'temperature': 0.5,
      }
    };

    return await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
    );
  }

  /// 3. TV HABER FORMATI (TV News & Teleprompter Script)
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

    final rawModel = preferredModel ?? await ApiKeyStorage.getModelForModule('tv');
    final modelToUse = GeminiModelConfig.sanitizeModel(rawModel);
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();

    final phoneticRules = isPhonetic
        ? """
ÖZEL SPİKER SESLENDİRME & FONETİK KURALLARI:
- Metni stüdyo spikerinin canlı yayında takılmadan okuyabilmesi ve Web/Cihaz Seslendirme (TTS) motorunun doğru telaffuz edebilmesi için fonetikleştir.
- Sayıları, yılları ve tarihleri mutlaka okunuşlarıyla yaz (Örn: "2026 yılında" yerine "iki bin yirmi altı yılında", "150 öğrenci" yerine "yüz elli öğrenci").
- Kısaltmaların telaffuzunu açıkça yaz (Örn: "TÜBİTAK" -> "Tübitak").
- Spikerin nefes alacağı ve duraklayacağı yerlere eğik çizgi (" / ") işareti koy.
"""
        : "";

    final videoInstruction = hasVideo
        ? """
Habere GÖRÜNTÜ / VTR MEVCUTTUR.
Biçimlendirme Kuralları:
1. KJ: Kısa, vurucu ve haberin özünü veren alt bant başlığı. (İlk satır 'KJ: ...' olmalıdır. Örn: KJ: $universityName'nde Yeni Proje)
2. CAM: Stüdyo spikerinin kameraya bakarak okuyacağı, izleyiciyi habere bağlayan 1-2 cümlelik dinamik giriş.
3. SES: Görüntü (VTR) üzerine seslendirilecek 1-2 cümlelik dış ses metni.
4. Video / Röportaj İbreleri: Haberdeki önemli kişilerin konuşma geçişleri (Örn: $rectorName Video).
5. SES: VTR devamı dış ses kapanış cümlesi.
"""
        : """
Habere GÖRÜNTÜ / VİDEO BULUNMAMAKTADIR. (SADECE STÜDYO SPİKERİ OKUYACAK)
Biçimlendirme Kuralları:
1. KJ: Kısa, dikkat çekici alt bant başlığı. (İlk satır 'KJ: ...' olmalıdır)
2. CAM: Stüdyo spikerinin doğrudan kameraya bakarak haberi baştan sona özetleyeceği, akıcı, net ve sade bülten metni (3-4 kısa ve net cümle).
3. Kesinlikle VTR, Video, SES gibi var olmayan görüntü ibreleri EKLEME.
""";

    final prompt = """
Sen $universityName $agencyName TV Haber Masası'nın kıdemli bülten koordinatörü ve spiker editörüsün.
Sana verilen haber metnini televizyon bülteni ve teleprompter akışına uygun olarak **kısa, öz, anlaşılır ve net** bir dille yeniden yaz.

$videoInstruction
$phoneticRules

ÖNEMLİ YAZIM KURALLARI:
- Asla markdown kalınlaştırma (**) veya yıldız işaretleri kullanma. Örneğin CAM: veya KJ: gibi ifadelerde yıldız asla kullanma.
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
        'temperature': 0.2,
      }
    };

    return await _executeWithFallback(
      apiKey: apiKey,
      primaryModel: modelToUse,
      payload: payload,
      cleanMarkdownStars: true,
    );
  }

  /// 4. EDİTORYAL DENETİM (TDK İmla Karnesi, Dil Denetimi & Yayına Hazır Saf Nihai Haber)
  static Future<GeminiResponseResult> editorialCheck({
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

    final rawModel = preferredModel ?? await ApiKeyStorage.getModelForModule('editorial');
    final modelToUse = GeminiModelConfig.sanitizeModel(rawModel);
    final universityName = await ApiKeyStorage.getUniversityName();
    final agencyName = await ApiKeyStorage.getAgencyName();
    final rectorName = await ApiKeyStorage.getRectorName();

    final prompt = """
Sen $universityName $agencyName Yayın Denetleme Kurulu Başkanı ve Baş Editörüsün.
Sana verilen haber metnini kurumsal haber ajansı ilkeleri, dil, üslup ve yazım kuralları bakımından titizlikle denetle.
Abartılı ve fazla süslü cümleleri tespit ederek temizle.

AŞAĞIDAKİ ETİKETLERİ VE BÖLÜM YAPISINI AYRI AYRI KULLANARAK YANIT VER:

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

### 🔍 Dil, Üslup ve TDK İmla Denetimi
- Dil & Anlatım: [Kurumsal ajans ilkelerine uygunluk, abartı ve süslü ifadelerden arındırma durumu]
- İmla & Noktalama: [TDK yazım kuralları değerlendirmesi]
- $agencyName Formatı: [Mahreç, Rektör $rectorName demeci ve tırnak işaretleri uyumu]
=== RAPOR_BITIS ===

=== DEGISIKLIKLER_BASLANGIC ===
### ✏️ Yapılan Düzeltmeler ve İyileştirme Maddeleri:
1. [Düzeltme 1]
2. [Düzeltme 2]
3. [Düzeltme 3]
=== DEGISIKLIKLER_BITIS ===

=== DUZELTILMIS_METIN_BASLANGIC ===
[Buraya SADECE VE SADECE haberin başlığı (# Başlık), spotu (**Spot**) ve $agencyName standartlarına göre abartıdan arındırılmış, sıfır hatayla yazılmış, KUSURSUZ VE YAYINA HAZIR SAF NİHAİ HABER METNİNİ yerleştir. Bu alana asla denetim puanı veya rapor cümlesi koyma!]
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
        'temperature': 0.15,
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

    final reportMatch = RegExp(r'=== RAPOR_BASLANGIC ===([\s\S]*?)=== RAPOR_BITIS ===', caseSensitive: false).firstMatch(raw);
    if (reportMatch != null) {
      report = reportMatch.group(1)?.trim() ?? '';
    }

    final changeMatch = RegExp(r'=== DEGISIKLIKLER_BASLANGIC ===([\s\S]*?)=== DEGISIKLIKLER_BITIS ===', caseSensitive: false).firstMatch(raw);
    if (changeMatch != null) {
      changelog = changeMatch.group(1)?.trim() ?? '';
    }

    final editedMatch = RegExp(r'=== DUZELTILMIS_METIN_BASLANGIC ===([\s\S]*?)=== DUZELTILMIS_METIN_BITIS ===', caseSensitive: false).firstMatch(raw);
    if (editedMatch != null) {
      editedText = editedMatch.group(1)?.trim() ?? '';
    }

    // Akıllı Fallback: Eğer etiketler eksikse raporu ve metni dikkatlice ayrıştır
    if (editedText.isEmpty) {
      if (raw.contains('=== DUZELTILMIS_METIN_BASLANGIC ===')) {
        final parts = raw.split('=== DUZELTILMIS_METIN_BASLANGIC ===');
        if (parts.length > 1) {
          editedText = parts[1].replaceAll('=== DUZELTILMIS_METIN_BITIS ===', '').trim();
        }
      }
    }

    if (report.isEmpty && editedText.isNotEmpty) {
      report = raw.replaceAll(editedText, '').replaceAll('=== DUZELTILMIS_METIN_BASLANGIC ===', '').replaceAll('=== DUZELTILMIS_METIN_BITIS ===', '').trim();
    }

    if (editedText.isEmpty) {
      // Eğer hiç etiket yoksa ama metinde başlık '# ' varsa başlığı bul
      final hashIndex = raw.indexOf('\n# ');
      if (hashIndex != -1) {
        report = raw.substring(0, hashIndex).trim();
        editedText = raw.substring(hashIndex).trim();
      } else {
        editedText = raw;
      }
    }

    return {
      'report': report,
      'changelog': changelog,
      'editedText': editedText,
    };
  }

  /// Fallback mekanizmalı API Çağrısı (Sadece kararlı Flash modelleri denenir)
  static Future<GeminiResponseResult> _executeWithFallback({
    required String apiKey,
    required String primaryModel,
    required Map<String, dynamic> payload,
    bool cleanMarkdownStars = false,
  }) async {
    final sanitizedPrimary = GeminiModelConfig.sanitizeModel(primaryModel);
    final modelsToTry = GeminiModelConfig.getFallbackModels(sanitizedPrimary);
    String primaryError = '';
    String lastError = 'Bilinmeyen bir hata oluştu.';

    for (int i = 0; i < modelsToTry.length; i++) {
      final model = modelsToTry[i];
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
          final noTextMsg = 'Model ($model) yanıt döndürdü ancak metin içeriği bulunamadı.';
          if (i == 0) primaryError = noTextMsg;
          lastError = noTextMsg;
        } else {
          final errBody = response.body;
          String msg = 'HTTP ${response.statusCode}';
          try {
            final errJson = jsonDecode(errBody);
            msg = errJson['error']?['message'] ?? msg;
          } catch (_) {}

          final formattedErr = '$model: $msg';
          if (i == 0) primaryError = formattedErr;
          lastError = formattedErr;

          // Eğer hata yetkilendirme (API key geçersiz / kota dolumu) ise diğer modelleri boşuna deneme
          if (response.statusCode == 400 && msg.toLowerCase().contains('api key not valid')) {
            break;
          }
          if (response.statusCode == 403) {
            break;
          }
        }
      } catch (e) {
        final catchErr = '$model: ${e.toString()}';
        if (i == 0) primaryError = catchErr;
        lastError = catchErr;
      }
    }

    // Kullanıcıya yanıltıcı fallback hatası yerine, asıl seçtiği modelin hatasını göster
    final displayError = primaryError.isNotEmpty ? primaryError : lastError;

    return GeminiResponseResult(
      isSuccess: false,
      text: '',
      usedModel: sanitizedPrimary,
      errorMessage: 'Gemini API ($sanitizedPrimary) çağrısı başarısız oldu:\n$displayError',
    );
  }
}
