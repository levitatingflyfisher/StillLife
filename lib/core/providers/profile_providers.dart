import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/profiles/data/repositories/profile_repository_impl.dart';
import '../../features/profiles/domain/entities/profile.dart';
import '../../features/profiles/domain/repositories/profile_repository.dart';
import 'database_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(databaseProvider)),
);

final profilesProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfiles(),
);

final activeProfileProvider =
    AsyncNotifierProvider<ActiveProfileNotifier, Profile?>(
      ActiveProfileNotifier.new,
    );

class ActiveProfileNotifier extends AsyncNotifier<Profile?> {
  ActiveProfileNotifier([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'active_profile_id';
  final FlutterSecureStorage _storage;

  @override
  Future<Profile?> build() async {
    final id = await _storage.read(key: _key);
    if (id == null) return null;
    final profiles = await ref.watch(profilesProvider.future);
    final match = profiles.firstWhereOrNull((p) => p.id == id);
    if (match != null) return match;
    // stored ID is stale (profile deleted) — fall back to default and
    // persist the new ID so next cold launch doesn't repeat the stale lookup.
    final fallback = profiles.firstWhereOrNull((p) => p.isDefault);
    if (fallback != null) {
      await _storage.write(key: _key, value: fallback.id);
    } else {
      await _storage.delete(key: _key);
    }
    return fallback;
  }

  Future<void> setActive(Profile? p) async {
    if (p == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: p.id);
    }
    state = AsyncData(p);
  }
}
