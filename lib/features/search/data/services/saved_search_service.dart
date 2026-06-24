import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedSearch {
  final String label;
  final String query;
  const SavedSearch({required this.label, required this.query});
  Map<String, dynamic> toJson() => {'label': label, 'query': query};
  factory SavedSearch.fromJson(Map<String, dynamic> j) =>
      SavedSearch(label: j['label'] as String, query: j['query'] as String);
}

class SavedSearchService {
  static const _key = 'saved_searches_v1';
  static const _maxSaved = 20;
  final FlutterSecureStorage _storage;
  SavedSearchService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<List<SavedSearch>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(SavedSearch.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(SavedSearch search) async {
    final list = await load();
    list.removeWhere((s) => s.label == search.label);
    list.insert(0, search);
    if (list.length > _maxSaved) list.removeRange(_maxSaved, list.length);
    await _storage.write(
      key: _key,
      value: jsonEncode(list.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> delete(String label) async {
    final list = await load();
    list.removeWhere((s) => s.label == label);
    await _storage.write(
      key: _key,
      value: jsonEncode(list.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await _storage.write(key: _key, value: null);
  }
}
