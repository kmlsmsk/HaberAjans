import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gemini_model_config.dart';

class ApiKeyStorage {
  static const String _keyApiKey = 'habervar_gemini_api_key';
  static const String _keyGlobalModel = 'habervar_gemini_global_model';
  static const String _keyAudioModel = 'habervar_gemini_audio_model';
  static const String _keyNewsModel = 'habervar_gemini_news_model';
  static const String _keyTvModel = 'habervar_gemini_tv_model';
  static const String _keyEditorialModel = 'habervar_gemini_editorial_model';
  static const String _keyModelsJson = 'habervar_gemini_models_v4';

  // Kurumsal Parametreler
  static const String _keyUniversityName = 'habervar_university_name';
  static const String _keyAgencyName = 'habervar_agency_name';
  static const String _keyRectorName = 'habervar_rector_name';
  static const String _keyCityName = 'habervar_city_name';
  static const String _keyPortalUrl = 'habervar_portal_url';

  static const String defaultUniversity = 'ABC Üniversitesi';
  static const String defaultAgency = 'ABC Ajansı';
  static const String defaultRector = 'Prof. Dr. Adı Soyadı';
  static const String defaultCity = 'İZMİR';
  static const String defaultPortal = 'www.abcajansi.com';
  static const String defaultModel = 'gemini-2.5-flash';

  // API Key
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey.trim());
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyApiKey) ?? prefs.getString('ege_gemini_api_key');
    return key;
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
    await prefs.remove('ege_gemini_api_key');
  }

  // Kurumsal Parametreler Get / Set
  static Future<void> saveUniversityName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUniversityName, name.trim());
  }

  static Future<String> getUniversityName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUniversityName) ??
        prefs.getString('ege_university_name') ??
        defaultUniversity;
  }

  static Future<void> saveAgencyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAgencyName, name.trim());
  }

  static Future<String> getAgencyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAgencyName) ??
        prefs.getString('ege_agency_name') ??
        defaultAgency;
  }

  static Future<void> saveRectorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRectorName, name.trim());
  }

  static Future<String> getRectorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRectorName) ??
        prefs.getString('ege_rector_name') ??
        defaultRector;
  }

  static Future<void> saveCityName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCityName, name.trim());
  }

  static Future<String> getCityName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCityName) ??
        prefs.getString('ege_city_name') ??
        defaultCity;
  }

  static Future<void> savePortalUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPortalUrl, url.trim());
  }

  static Future<String> getPortalUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPortalUrl) ??
        prefs.getString('ege_portal_url') ??
        defaultPortal;
  }

  // Model CRUD Yönetimi
  static Future<List<GeminiModelOption>> getAllModels() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyModelsJson);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List;
        final loaded = list
            .map((item) => GeminiModelOption.fromJson(item as Map<String, dynamic>))
            .where((m) =>
                m.id.startsWith('gemini-2') ||
                m.id.startsWith('gemini-1.5') ||
                m.isCustom)
            .toList();
        if (loaded.isNotEmpty) return loaded;
      } catch (_) {}
    }
    return List.from(GeminiModelConfig.defaultBuiltInModels);
  }

  static Future<void> saveAllModels(List<GeminiModelOption> models) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(models.map((m) => m.toJson()).toList());
    await prefs.setString(_keyModelsJson, jsonStr);
  }

  static Future<void> addOrUpdateModel(GeminiModelOption model) async {
    final models = await getAllModels();
    final index = models.indexWhere((m) => m.id == model.id);
    if (index >= 0) {
      models[index] = model;
    } else {
      models.add(model);
    }
    await saveAllModels(models);
  }

  static Future<void> deleteModel(String modelId) async {
    final models = await getAllModels();
    models.removeWhere((m) => m.id == modelId);
    await saveAllModels(models);
  }

  static Future<void> resetModelsToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyModelsJson);
    await prefs.remove('ege_gemini_models_v3');
  }

  // Modül Model Seçimleri
  static Future<void> saveModel(String moduleKey, String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = GeminiModelConfig.sanitizeModel(modelId);
    await prefs.setString(moduleKey, sanitized);
  }

  static Future<String> getModelForModule(String moduleType) async {
    final prefs = await SharedPreferences.getInstance();
    final globalModel = GeminiModelConfig.sanitizeModel(
        prefs.getString(_keyGlobalModel) ?? prefs.getString('ege_gemini_global_model'));

    String selected;
    switch (moduleType) {
      case 'audio':
        selected = prefs.getString(_keyAudioModel) ??
            prefs.getString('ege_gemini_audio_model') ??
            globalModel;
        break;
      case 'news':
        selected = prefs.getString(_keyNewsModel) ??
            prefs.getString('ege_gemini_news_model') ??
            globalModel;
        break;
      case 'tv':
        selected = prefs.getString(_keyTvModel) ??
            prefs.getString('ege_gemini_tv_model') ??
            globalModel;
        break;
      case 'editorial':
        selected = prefs.getString(_keyEditorialModel) ??
            prefs.getString('ege_gemini_editorial_model') ??
            globalModel;
        break;
      case 'global':
      default:
        selected = globalModel;
        break;
    }
    return GeminiModelConfig.sanitizeModel(selected);
  }

  static Future<void> saveAllModuleModels({
    required String globalModel,
    required String audioModel,
    required String newsModel,
    required String tvModel,
    required String editorialModel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGlobalModel, GeminiModelConfig.sanitizeModel(globalModel));
    await prefs.setString(_keyAudioModel, GeminiModelConfig.sanitizeModel(audioModel));
    await prefs.setString(_keyNewsModel, GeminiModelConfig.sanitizeModel(newsModel));
    await prefs.setString(_keyTvModel, GeminiModelConfig.sanitizeModel(tvModel));
    await prefs.setString(_keyEditorialModel, GeminiModelConfig.sanitizeModel(editorialModel));
  }
}
