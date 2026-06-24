import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/inventory/presentation/screens/item_detail_screen.dart';
import '../features/inventory/presentation/screens/item_edit_screen.dart';
import '../features/locations/presentation/screens/rooms_screen.dart';
import '../features/locations/presentation/screens/room_detail_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/reports/presentation/screens/policy_screen.dart';
import '../features/reports/presentation/screens/policy_add_edit_screen.dart';
import '../features/inventory/presentation/screens/category_management_screen.dart';
import '../features/inventory/presentation/screens/tag_management_screen.dart';
import '../features/billing/presentation/screens/pro_status_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/llm_settings_screen.dart';
import '../features/video_analysis/presentation/screens/processing_screen.dart';
import '../features/video_analysis/presentation/screens/review_screen.dart';
import '../features/scanning/presentation/screens/barcode_scanner_screen.dart';
import '../features/scanning/presentation/screens/receipt_capture_screen.dart';
import '../features/video_analysis/presentation/screens/video_capture_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_add_screen.dart';
import '../features/maintenance/domain/entities/maintenance_log.dart';
import '../features/sync/presentation/screens/sync_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/settings/presentation/screens/webdav_settings_screen.dart';
import '../features/labels/presentation/screens/item_label_screen.dart';
import '../features/labels/presentation/screens/container_label_screen.dart';
import '../features/locations/presentation/screens/container_detail_screen.dart';
import '../features/inventory/presentation/screens/photo_viewer_screen.dart';
import '../features/inventory/domain/entities/item_suggestion.dart';
import '../features/inventory/domain/entities/photo.dart';
import '../features/loans/presentation/screens/all_loans_screen.dart';
import '../features/inventory/presentation/screens/low_stock_screen.dart';
import '../features/import/presentation/screens/import_review_screen.dart';
import '../features/import/presentation/screens/bank_column_map_screen.dart';
import '../features/import/domain/import_review_item.dart';
import '../features/profiles/presentation/screens/profile_management_screen.dart';
import '../features/chat/presentation/screens/item_chat_screen.dart';
import '../features/insurance/presentation/screens/what_should_i_insure_screen.dart';
import '../services/import/bank_statement_parser.dart';
import 'shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod provider — overridden in main.dart with the correct initial
/// location after the onboarding-complete flag has been checked.
final routerProvider = Provider<GoRouter>(
  (ref) => buildAppRouter(initialLocation: '/dashboard'),
);

GoRouter buildAppRouter({String initialLocation = '/dashboard'}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inventory',
              name: 'inventory',
              builder: (context, state) => const InventoryScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addItem',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final params = state.uri.queryParameters;
                    final suggestion = state.extra as ItemSuggestion?;
                    return ItemEditScreen(
                      initialRoomId: params['roomId'],
                      initialContainerId: params['containerId'],
                      initialBarcode: params['barcode'],
                      initialSuggestion: suggestion,
                      showAiBanner:
                          suggestion == null && params['barcode'] == null,
                    );
                  },
                ),
                GoRoute(
                  path: ':itemId',
                  name: 'itemDetail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final itemId = state.pathParameters['itemId']!;
                    return ItemDetailScreen(itemId: itemId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'editItem',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final itemId = state.pathParameters['itemId']!;
                        return ItemEditScreen(itemId: itemId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/rooms',
              name: 'rooms',
              builder: (context, state) => const RoomsScreen(),
              routes: [
                GoRoute(
                  path: ':roomId',
                  name: 'roomDetail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    return RoomDetailScreen(roomId: roomId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (context, state) => const ReportsScreen(),
              routes: [
                GoRoute(
                  path: 'policies',
                  name: 'policies',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, _) => const PolicyScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      name: 'addPolicy',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (_, _) => const PolicyAddEditScreen(),
                    ),
                    GoRoute(
                      path: ':policyId/edit',
                      name: 'editPolicy',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final extra = state.extra as dynamic;
                        return PolicyAddEditScreen(existing: extra);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const SearchScreen(),
    ),
    GoRoute(
      path: '/sync',
      name: 'sync',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const SyncScreen(),
    ),
    GoRoute(
      path: '/loans',
      name: 'allLoans',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const AllLoansScreen(),
    ),
    GoRoute(
      path: '/low-stock',
      name: 'lowStock',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const LowStockScreen(),
    ),
    GoRoute(
      path: '/import/review',
      name: 'importReview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final items = state.extra as List<ImportReviewItem>;
        return ImportReviewScreen(items: items);
      },
    ),
    GoRoute(
      path: '/import/bank-columns',
      name: 'bankColumns',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BankColumnMapScreen(
          csvContent: extra?['csvContent'] as String? ?? '',
          autoDetected:
              extra?['autoDetected'] as BankColumnMap? ?? const BankColumnMap(),
          truncated: extra?['truncated'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'tags',
          name: 'tagManagement',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TagManagementScreen(),
        ),
        GoRoute(
          path: 'categories',
          name: 'categoryManagement',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: 'webdav',
          name: 'webdavSettings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const WebDavSettingsScreen(),
        ),
        GoRoute(
          path: 'llm',
          name: 'llmSettings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const LlmSettingsScreen(),
        ),
        GoRoute(
          path: 'profiles',
          name: 'profiles',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const ProfileManagementScreen(),
        ),
        GoRoute(
          path: 'pro',
          name: 'pro',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const ProStatusScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/items/:itemId/label',
      name: 'itemLabel',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return ItemLabelScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: '/items/:id/chat',
      name: 'itemChat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final itemId = state.pathParameters['id']!;
        return ItemChatScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: '/insurance/gaps',
      name: 'insuranceGaps',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const WhatShouldIInsureScreen(),
    ),
    GoRoute(
      path: '/containers/:containerId',
      name: 'containerDetail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final containerId = state.pathParameters['containerId']!;
        return ContainerDetailScreen(containerId: containerId);
      },
    ),
    GoRoute(
      path: '/containers/:containerId/label',
      name: 'containerLabel',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final containerId = state.pathParameters['containerId']!;
        return ContainerLabelScreen(containerId: containerId);
      },
    ),
    GoRoute(
      path: '/scan/barcode',
      name: 'barcodeScanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final returnMode = state.uri.queryParameters['returnMode'] == 'true';
        return BarcodeScannerScreen(returnMode: returnMode);
      },
    ),
    GoRoute(
      path: '/scan/receipt',
      name: 'receiptCapture',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, _) => const ReceiptCaptureScreen(),
    ),
    GoRoute(
      path: '/video/capture',
      name: 'videoCapture',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'];
        return VideoCaptureScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/video/processing',
      name: 'videoProcessing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProcessingScreen(),
    ),
    GoRoute(
      path: '/video/review',
      name: 'videoReview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/photo/view',
      name: 'photoViewer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final photos = (extra?['photos'] as List?)?.cast<Photo>() ?? [];
        final initialIndex = extra?['initialIndex'] as int? ?? 0;
        return PhotoViewerScreen(photos: photos, initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/maintenance',
      name: 'maintenance',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MaintenanceScreen(),
      routes: [
        GoRoute(
          path: 'add',
          name: 'addMaintenance',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MaintenanceAddScreen(),
        ),
        GoRoute(
          path: ':logId/edit',
          name: 'editMaintenance',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              MaintenanceAddScreen(existing: state.extra as MaintenanceLog?),
        ),
      ],
    ),
  ],
);
