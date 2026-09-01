import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/sync_providers.dart';
import '../data/recently_deleted_repository.dart';

final recentlyDeletedRepositoryProvider = Provider<RecentlyDeletedRepository>(
  (ref) => RecentlyDeletedRepository(
    ref.watch(databaseProvider),
    crdt: ref.watch(crdtManagerProvider),
  ),
);

/// The Undo offer for deletes whose screen closes (an item, a room) or that
/// happen on a tab (bulk delete). The shell draws it above the navigation
/// bar, so it survives the pop. It has no timer: it ends on Undo, on
/// Dismiss, or when the next delete replaces it. Recently deleted in
/// Settings is the lasting way back for items.
final shellUndoControllerProvider = Provider<OhUndoController>((ref) {
  final controller = OhUndoController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// An Undo offer that belongs to one screen (policies, maintenance,
/// categories, tags), keyed by the screen's name. It is disposed with the
/// screen, and the screen's [OhUndoBar] commits on dispose, so the offer
/// lasts exactly until the person leaves — never on a timer.
final screenUndoControllerProvider = Provider.autoDispose
    .family<OhUndoController, String>((ref, screen) {
      final controller = OhUndoController();
      ref.onDispose(controller.dispose);
      return controller;
    });
