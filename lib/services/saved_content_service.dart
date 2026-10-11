import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedNewsItem {
  final String id;
  String title;
  String content;
  String report;
  String score;
  final DateTime createdAt;
  DateTime updatedAt;

  SavedNewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.report = '',
    this.score = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'report': report,
    'score': score,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedNewsItem.fromJson(Map<String, dynamic> json) => SavedNewsItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Başlıksız Haber',
    content: json['content'] as String? ?? '',
    report: json['report'] as String? ?? '',
    score: json['score'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class SavedPrompterItem {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  SavedPrompterItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedPrompterItem.fromJson(Map<String, dynamic> json) => SavedPrompterItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'TV Prompter Bülteni',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class SavedContentService {
  static const String _keySavedNews = 'habervar_saved_news_v1';
  static const String _keySavedPrompter = 'habervar_saved_prompter_v1';

  // --- NİHAİ HABERLER (CRUD) ---
  static Future<List<SavedNewsItem>> getSavedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySavedNews);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => SavedNewsItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNews(SavedNewsItem item) async {
    final list = await getSavedNews();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedNews, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteNews(String id) async {
    final list = await getSavedNews();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedNews, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // --- PROMPTER METİNLERİ (CRUD) ---
  static Future<List<SavedPrompterItem>> getSavedPrompters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySavedPrompter);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => SavedPrompterItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePrompter(SavedPrompterItem item) async {
    final list = await getSavedPrompters();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedPrompter, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> deletePrompter(String id) async {
    final list = await getSavedPrompters();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedPrompter, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
