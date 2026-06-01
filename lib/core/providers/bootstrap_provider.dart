import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inventory/domain/repositories/category_repository.dart';
import '../../features/locations/domain/entities/property.dart';
import '../../features/locations/domain/repositories/property_repository.dart';
import '../../features/locations/domain/repositories/room_repository.dart';
import 'repository_providers.dart';

/// Runs once on app start. Seeds default categories and a default
/// property with rooms when the database is empty.
final bootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    _seedCategoriesIfEmpty(ref.read(categoryRepositoryProvider)),
    _seedPropertyIfEmpty(
      ref.read(propertyRepositoryProvider),
      ref.read(roomRepositoryProvider),
    ),
  ]);
});

Future<void> _seedCategoriesIfEmpty(CategoryRepository repo) async {
  // Listen once to check if categories exist
  final categories = await repo.watchCategories().first;
  if (categories.isEmpty) {
    await repo.seedDefaults();
  }
}

Future<void> _seedPropertyIfEmpty(
  PropertyRepository propertyRepo,
  RoomRepository roomRepo,
) async {
  final properties = await propertyRepo.watchProperties().first;
  if (properties.isEmpty) {
    final now = DateTime.now();
    final result = await propertyRepo.createProperty(
      Property(
        id: '',
        name: 'My Home',
        type: PropertyType.home,
        createdAt: now,
        modifiedAt: now,
      ),
    );
    if (result.isSuccess) {
      await roomRepo.seedDefaults(result.value.id);
    }
  }
}
