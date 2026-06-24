import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/quantity_controller.dart';
import 'package:still_life/services/notifications/notification_service.dart';

class _MockRepo extends Mock implements ItemRepository {}

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

Item _item({double? quantity, double? threshold}) => Item(
  id: 'i1',
  name: 'Coffee',
  description: '',
  categoryId: 'c1',
  roomId: 'r1',
  isInsured: false,
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
  quantity: quantity,
  lowStockThreshold: threshold,
);

void main() {
  late _MockRepo repo;
  late _MockPlugin plugin;
  late QuantityController ctrl;

  setUp(() {
    repo = _MockRepo();
    plugin = _MockPlugin();
    when(
      () => plugin.show(any(), any(), any(), any()),
    ).thenAnswer((_) async {});
    ctrl = QuantityController(
      repo: repo,
      notifications: NotificationService(plugin: plugin),
    );
  });

  test('decrement calls repo.decrementQuantity', () async {
    when(
      () => repo.decrementQuantity('i1'),
    ).thenAnswer((_) async => Success(_item(quantity: 9.0, threshold: 3.0)));
    await ctrl.decrement('i1');
    verify(() => repo.decrementQuantity('i1')).called(1);
  });

  test(
    'fires low-stock notification when result is at/below threshold',
    () async {
      when(
        () => repo.decrementQuantity('i1'),
      ).thenAnswer((_) async => Success(_item(quantity: 2.0, threshold: 3.0)));
      await ctrl.decrement('i1');
      verify(() => plugin.show(any(), any(), any(), any())).called(1);
    },
  );

  test('does not fire notification when quantity is above threshold', () async {
    when(
      () => repo.decrementQuantity('i1'),
    ).thenAnswer((_) async => Success(_item(quantity: 5.0, threshold: 3.0)));
    await ctrl.decrement('i1');
    verifyNever(() => plugin.show(any(), any(), any(), any()));
  });

  test('does not fire notification when lowStockThreshold is null', () async {
    when(
      () => repo.decrementQuantity('i1'),
    ).thenAnswer((_) async => Success(_item(quantity: 2.0)));
    await ctrl.decrement('i1');
    verifyNever(() => plugin.show(any(), any(), any(), any()));
  });

  test('silently swallows repo failure', () async {
    when(
      () => repo.decrementQuantity('i1'),
    ).thenAnswer((_) async => const Err(DatabaseFailure('oops')));
    await expectLater(ctrl.decrement('i1'), completes);
  });
}
