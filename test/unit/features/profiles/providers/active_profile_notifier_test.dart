import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

Profile _profile({
  String id = 'p-1',
  String name = 'Alice',
  bool isDefault = false,
}) => Profile(
  id: id,
  name: name,
  colorHex: '#FF5733',
  avatarEmoji: '🐱',
  isDefault: isDefault,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

ProviderContainer _makeContainer({
  required _MockStorage storage,
  List<Profile> profiles = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      profilesProvider.overrideWith((ref) => Stream.value(profiles)),
      activeProfileProvider.overrideWith(() => ActiveProfileNotifier(storage)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
  });

  test('build returns null when no active_profile_id key exists', () async {
    when(
      () => storage.read(key: 'active_profile_id'),
    ).thenAnswer((_) async => null);

    final container = _makeContainer(storage: storage);
    final result = await container.read(activeProfileProvider.future);

    expect(result, isNull);
  });

  test(
    'build returns the matching profile when a valid ID is stored',
    () async {
      final alice = _profile(id: 'p-1', name: 'Alice');
      final bob = _profile(id: 'p-2', name: 'Bob');

      when(
        () => storage.read(key: 'active_profile_id'),
      ).thenAnswer((_) async => 'p-1');

      final container = _makeContainer(
        storage: storage,
        profiles: [alice, bob],
      );
      final result = await container.read(activeProfileProvider.future);

      expect(result, equals(alice));
    },
  );

  test('build falls back to default profile when stored ID is stale', () async {
    final defaultProfile = _profile(
      id: 'p-default',
      name: 'Default',
      isDefault: true,
    );
    final otherProfile = _profile(
      id: 'p-other',
      name: 'Other',
      isDefault: false,
    );

    // stored ID refers to a profile that no longer exists
    when(
      () => storage.read(key: 'active_profile_id'),
    ).thenAnswer((_) async => 'p-deleted');
    // Fallback should also persist the resolved default ID so the next
    // cold launch doesn't repeat the stale-lookup dance.
    when(
      () => storage.write(key: 'active_profile_id', value: 'p-default'),
    ).thenAnswer((_) async {});

    final container = _makeContainer(
      storage: storage,
      profiles: [defaultProfile, otherProfile],
    );
    final result = await container.read(activeProfileProvider.future);

    expect(result, equals(defaultProfile));
    verify(
      () => storage.write(key: 'active_profile_id', value: 'p-default'),
    ).called(1);
  });

  test('build deletes stale key when no default profile exists', () async {
    final other = _profile(id: 'p-other', name: 'Other', isDefault: false);

    when(
      () => storage.read(key: 'active_profile_id'),
    ).thenAnswer((_) async => 'p-deleted');
    when(
      () => storage.delete(key: 'active_profile_id'),
    ).thenAnswer((_) async {});

    final container = _makeContainer(storage: storage, profiles: [other]);
    final result = await container.read(activeProfileProvider.future);

    expect(result, isNull);
    verify(() => storage.delete(key: 'active_profile_id')).called(1);
  });

  test('setActive persists the ID to storage and updates state', () async {
    final alice = _profile(id: 'p-1', name: 'Alice');

    when(
      () => storage.read(key: 'active_profile_id'),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(key: 'active_profile_id', value: 'p-1'),
    ).thenAnswer((_) async {});

    final container = _makeContainer(storage: storage, profiles: [alice]);
    // Wait for initial build
    await container.read(activeProfileProvider.future);

    final notifier = container.read(activeProfileProvider.notifier);
    await notifier.setActive(alice);

    verify(
      () => storage.write(key: 'active_profile_id', value: 'p-1'),
    ).called(1);

    final current = container.read(activeProfileProvider).valueOrNull;
    expect(current, equals(alice));
  });

  test(
    'setActive(null) removes the key from storage and updates state to null',
    () async {
      final alice = _profile(id: 'p-1', name: 'Alice');

      when(
        () => storage.read(key: 'active_profile_id'),
      ).thenAnswer((_) async => 'p-1');
      when(
        () => storage.delete(key: 'active_profile_id'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(storage: storage, profiles: [alice]);
      // Wait for initial build
      await container.read(activeProfileProvider.future);

      final notifier = container.read(activeProfileProvider.notifier);
      await notifier.setActive(null);

      verify(() => storage.delete(key: 'active_profile_id')).called(1);

      final current = container.read(activeProfileProvider).valueOrNull;
      expect(current, isNull);
    },
  );
}
