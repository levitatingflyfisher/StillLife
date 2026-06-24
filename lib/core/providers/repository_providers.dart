import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/billing/data/stripe_billing_service_impl.dart'
    show kHostedBearerStorageKey;
import '../../features/search/data/services/saved_search_service.dart';
import 'billing_providers.dart' show accountProvider, kHostedBaseUrl;
import '../../services/voice/voice_input_service.dart';
import '../../services/database/database.dart' show PriceHistoryEntry;
import '../../services/storage/photo_storage_service.dart';
import '../../services/ml/analysis_provider.dart';
import '../../services/ml/on_device_provider.dart';
import '../../services/ml/ollama_provider.dart';
import '../../services/ml/cloud_api_provider.dart';
import '../../services/ml/hosted_provider.dart';
import '../../services/ml/provider_manager.dart';
import '../../features/inventory/data/services/item_photo_analysis_service.dart';
import '../../features/settings/presentation/screens/llm_settings_screen.dart'
    show
        llmTierPriorityProvider,
        llmTierEnabledProvider,
        ollamaHostProvider,
        ollamaPortProvider,
        ollamaModelProvider;

import '../../services/export/csv_export_service.dart';
import '../../services/export/json_export_service.dart';
import '../../services/export/import_service.dart';
import '../../services/product_lookup/product_lookup_service.dart';
import '../../features/inventory/data/repositories/item_repository_impl.dart';
import '../../features/inventory/data/repositories/category_repository_impl.dart';
import '../../features/inventory/data/repositories/tag_repository_impl.dart';
import '../../features/inventory/data/repositories/photo_repository_impl.dart';
import '../../features/inventory/domain/repositories/item_repository.dart';
import '../../features/inventory/domain/repositories/category_repository.dart';
import '../../features/inventory/domain/repositories/tag_repository.dart';
import '../../features/inventory/domain/repositories/photo_repository.dart';
import '../../features/locations/data/repositories/container_repository_impl.dart';
import '../../features/locations/data/repositories/property_repository_impl.dart';
import '../../features/locations/data/repositories/room_repository_impl.dart';
import '../../features/locations/domain/repositories/container_repository.dart';
import '../../features/locations/domain/repositories/property_repository.dart';
import '../../features/locations/domain/repositories/room_repository.dart';
import '../../features/reports/data/repositories/policy_repository_impl.dart';
import '../../features/reports/domain/repositories/policy_repository.dart';
import '../../features/maintenance/data/repositories/maintenance_repository_impl.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/loans/data/repositories/loan_repository_impl.dart';
import '../../features/loans/domain/repositories/loan_repository.dart';
import '../../services/seeding/consumable_seeder.dart';
import '../../services/import/import_fallback_seeder.dart';
import '../../services/import/amazon_import_service.dart';
import '../../services/import/import_receipt_ocr_service.dart';
import 'database_provider.dart';

final _photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

// Stable Dio instance for Ollama/cloud/hosted providers.
// Separate from the product lookup Dio to allow independent config.
final _mlDioProvider = Provider<Dio>((ref) => Dio());

// Stable Dio for the product lookup service. Previously the service was
// constructed with a fresh `Dio()` on every provider rebuild, leaking
// connection pools. A separate provider gives us a single instance for
// the app lifetime that can also be overridden cleanly in tests.
final _productLookupDioProvider = Provider<Dio>((ref) => Dio());

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(
    ref.watch(databaseProvider),
    ref.watch(_photoStorageServiceProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(databaseProvider));
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepositoryImpl(ref.watch(databaseProvider));
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(ref.watch(databaseProvider));
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepositoryImpl(ref.watch(databaseProvider));
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl(ref.watch(databaseProvider));
});

final containerRepositoryProvider = Provider<ContainerRepository>((ref) {
  return ContainerRepositoryImpl(ref.watch(databaseProvider));
});

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return PolicyRepositoryImpl(ref.watch(databaseProvider));
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepositoryImpl(ref.watch(databaseProvider));
});

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepositoryImpl(ref.watch(databaseProvider)),
);

final priceHistoryProvider =
    StreamProvider.family<List<PriceHistoryEntry>, String>((ref, itemId) {
      final db = ref.watch(databaseProvider);
      return db.priceHistoryDao.watchPriceHistory(itemId);
    });

final exportServiceProvider = Provider<JsonExportService>((ref) {
  return JsonExportService(ref.watch(databaseProvider));
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.watch(databaseProvider));
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(ref.watch(databaseProvider));
});

final productLookupServiceProvider = Provider<ProductLookupService>((ref) {
  return ProductLookupService(
    ref.watch(_productLookupDioProvider),
    ref.watch(databaseProvider),
  );
});

final providerManagerProvider = Provider<ProviderManager>((ref) {
  final priority =
      ref.watch(llmTierPriorityProvider).valueOrNull ??
      AnalysisTier.values.toList();
  final enabled =
      ref.watch(llmTierEnabledProvider).valueOrNull ??
      {for (final t in AnalysisTier.values) t: true};
  final ollamaHost = ref.watch(ollamaHostProvider).valueOrNull ?? 'localhost';
  final ollamaPort = ref.watch(ollamaPortProvider).valueOrNull ?? 11434;
  final ollamaModel = ref.watch(ollamaModelProvider).valueOrNull ?? 'llava';
  final dio = ref.watch(_mlDioProvider); // stable, not recreated

  final ollamaBaseUrl = 'http://$ollamaHost:$ollamaPort';

  final allProviders = <AnalysisProvider>[
    OnDeviceProvider(),
    OllamaProvider(dio: dio, baseUrl: ollamaBaseUrl, model: ollamaModel),
    CloudApiProvider(dio: dio, apiKey: '', apiType: CloudApiType.openai),
    HostedProvider(
      dio: dio,
      baseUrl: kHostedBaseUrl,
      apiKeyProvider: () async {
        const storage = FlutterSecureStorage();
        return (await storage.read(key: kHostedBearerStorageKey)) ?? '';
      },
      onUnauthorized: () async {
        // Clear the stored bearer and invalidate the account provider so
        // the UI reflects the logged-out state.
        const storage = FlutterSecureStorage();
        await storage.delete(key: kHostedBearerStorageKey);
        ref.invalidate(accountProvider);
      },
    ),
  ];

  final enabledProviders = allProviders
      .where((p) => enabled[p.tier] ?? true)
      .toList();

  final filteredPriority = priority.where((t) => enabled[t] ?? true).toList();

  return ProviderManager(
    providers: enabledProviders,
    priorityOrder: filteredPriority,
  );
});

final itemPhotoAnalysisServiceProvider = Provider<ItemPhotoAnalysisService>((
  ref,
) {
  return ItemPhotoAnalysisService(ref.watch(providerManagerProvider));
});

final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});

final savedSearchServiceProvider = Provider<SavedSearchService>((ref) {
  return SavedSearchService();
});

final consumableSeederProvider = Provider<ConsumableSeeder>((ref) {
  return ConsumableSeeder(database: ref.watch(databaseProvider));
});

// --- Import services ---

final importFallbackSeederProvider = Provider<ImportFallbackSeeder>(
  (ref) => ImportFallbackSeeder(database: ref.watch(databaseProvider)),
);

final amazonImportServiceProvider = Provider<AmazonImportService>(
  (ref) => AmazonImportService(),
);

final receiptOcrServiceProvider = Provider<ImportReceiptOcrService>(
  (ref) => ImportReceiptOcrService(
    providerManager: ref.watch(providerManagerProvider),
  ),
);
