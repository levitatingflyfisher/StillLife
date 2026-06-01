import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/search/data/services/saved_search_service.dart';

class _FakeStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  late SavedSearchService service;
  setUp(() => service = SavedSearchService(storage: _FakeStorage()));

  test('load returns empty list when nothing saved', () async {
    expect(await service.load(), isEmpty);
  });

  test('save and load round-trip', () async {
    await service.save(const SavedSearch(label: 'cameras', query: 'cameras'));
    final result = await service.load();
    expect(result.map((s) => s.label), contains('cameras'));
  });

  test('delete removes by label', () async {
    await service.save(const SavedSearch(label: 'cameras', query: 'cameras'));
    await service.delete('cameras');
    expect(await service.load(), isEmpty);
  });

  test('caps at 20 — oldest dropped', () async {
    for (int i = 0; i < 22; i++) {
      await service.save(SavedSearch(label: 'search $i', query: 'search $i'));
    }
    final result = await service.load();
    expect(result.length, equals(20));
    expect(result.map((s) => s.label), contains('search 21'));
    expect(result.map((s) => s.label), isNot(contains('search 0')));
  });

  test('saving duplicate label moves it to front', () async {
    await service.save(const SavedSearch(label: 'query', query: 'query'));
    await service.save(const SavedSearch(label: 'other', query: 'other'));
    await service.save(const SavedSearch(label: 'query', query: 'query'));
    final result = await service.load();
    expect(result.first.label, equals('query'));
    expect(result.length, equals(2));
  });
}
