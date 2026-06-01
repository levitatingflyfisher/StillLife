import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/category.dart';
import '../../../inventory/presentation/controllers/category_controller.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/saved_search_service.dart';
import '../../domain/services/nl_query_parser.dart';

/// Bound NlQueryParser — rebuilds when rooms/categories/containers change.
final nlQueryParserProvider = Provider<NlQueryParser>((ref) {
  final rooms = ref.watch(roomsProvider).valueOrNull ?? <Room>[];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? <Category>[];
  final containers =
      ref.watch(allContainersProvider).valueOrNull ?? <StorageContainer>[];
  return NlQueryParser(
    rooms: rooms,
    categories: categories,
    containers: containers,
  );
});

/// Reactive list of saved searches.
final savedSearchesProvider = FutureProvider<List<SavedSearch>>((ref) async {
  final service = ref.watch(savedSearchServiceProvider);
  return service.load();
});
