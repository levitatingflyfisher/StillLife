import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/notifications/notification_service.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeNotificationDetails());
  });

  test('showLowStockAlert calls plugin.show with low-stock message', () async {
    final plugin = _MockPlugin();
    when(
      () => plugin.show(any(), any(), any(), any()),
    ).thenAnswer((_) async {});
    final svc = NotificationService(plugin: plugin);

    await svc.showLowStockAlert(
      itemId: 'item-1',
      itemName: 'Coffee',
      quantity: 2.0,
      threshold: 3.0,
    );

    verify(
      () => plugin.show(
        any(),
        'Low Stock: Coffee',
        '2.0 remaining (threshold: 3.0)',
        any(),
      ),
    ).called(1);
  });
}
