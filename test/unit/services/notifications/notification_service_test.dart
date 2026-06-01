import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

// Fake instances for mocktail fallback registration
class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  setUpAll(() {
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(DateTimeComponents.dateAndTime);
  });

  late MockPlugin mockPlugin;
  late NotificationService service;

  setUp(() {
    mockPlugin = MockPlugin();
    service = NotificationService(plugin: mockPlugin);

    when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
    when(
      () => mockPlugin.show(any(), any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});
    when(
      () => mockPlugin.zonedSchedule(
        any(),
        any(),
        any(),
        any(),
        any(),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        uiLocalNotificationDateInterpretation: any(
          named: 'uiLocalNotificationDateInterpretation',
        ),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    when(
      () => mockPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
  });

  group('NotificationService.initialize', () {
    test('calls plugin.initialize', () async {
      await service.initialize();
      verify(() => mockPlugin.initialize(any())).called(1);
    });
  });

  group('NotificationService.showImmediate', () {
    test('calls plugin.show with supplied title and body', () async {
      await service.showImmediate(id: 1, title: 'T', body: 'B');
      verify(() => mockPlugin.show(1, 'T', 'B', any())).called(1);
    });
  });

  group('NotificationService.cancelWarrantyReminder', () {
    test('calls plugin.cancel', () async {
      await service.cancelWarrantyReminder('item-1');
      verify(() => mockPlugin.cancel(any())).called(1);
    });
  });

  group('NotificationService.cancelMaintenanceReminder', () {
    test('calls plugin.cancel', () async {
      await service.cancelMaintenanceReminder('log-1');
      verify(() => mockPlugin.cancel(any())).called(1);
    });
  });

  group('NotificationService.scheduleWarrantyReminder', () {
    test('does NOT schedule when reminder date is in the past', () async {
      // expiryDate in the past → scheduledDate is also in the past
      await service.scheduleWarrantyReminder(
        itemId: 'item-1',
        itemName: 'TV',
        expiryDate: DateTime.now().subtract(const Duration(days: 60)),
        daysBefore: 30,
      );
      verifyNever(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
        ),
      );
    });

    test('schedules when reminder date is in the future', () async {
      await service.scheduleWarrantyReminder(
        itemId: 'item-2',
        itemName: 'Fridge',
        expiryDate: DateTime.now().add(const Duration(days: 60)),
        daysBefore: 30,
      );
      verify(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).called(1);
    });
  });

  group('NotificationService.scheduleMaintenanceReminder', () {
    test('does NOT schedule when reminder date is in the past', () async {
      await service.scheduleMaintenanceReminder(
        logId: 'log-1',
        title: 'Oil Change',
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
        daysBefore: 7,
      );
      verifyNever(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
        ),
      );
    });

    test('schedules when reminder date is in the future', () async {
      await service.scheduleMaintenanceReminder(
        logId: 'log-2',
        title: 'HVAC Filter',
        dueDate: DateTime.now().add(const Duration(days: 30)),
        daysBefore: 7,
      );
      verify(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).called(1);
    });
  });
}
