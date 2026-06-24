import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/locations/domain/entities/property.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/features/reports/domain/entities/policy.dart';
import 'package:still_life/features/reports/domain/repositories/policy_repository.dart';
import 'package:still_life/features/reports/presentation/controllers/policy_controller.dart';
import 'package:still_life/features/reports/presentation/screens/policy_add_edit_screen.dart';

// Minimal stub repo for the controller.
class _FakePolicyRepo implements PolicyRepository {
  @override
  Stream<List<Policy>> watchAll() => const Stream.empty();
  @override
  Future<Result<List<Policy>>> getByPropertyId(_) async => const Success([]);
  @override
  Future<Result<Policy>> create(_) async => Success(
    Policy(id: 'x', propertyId: 'p', provider: 'x', createdAt: DateTime.now()),
  );
  @override
  Future<Result<Policy>> update(_) async => Success(
    Policy(id: 'x', propertyId: 'p', provider: 'x', createdAt: DateTime.now()),
  );
  @override
  Future<Result<void>> delete(_) async => const Success(null);
}

// Stub controller that records calls.
class _FakePolicyController extends PolicyController {
  final List<String> calls = [];

  _FakePolicyController() : super(_FakePolicyRepo());

  @override
  Future<bool> add(_) async {
    calls.add('add');
    return true;
  }

  @override
  Future<bool> edit(_) async {
    calls.add('edit');
    return true;
  }
}

void main() {
  final property = Property(
    id: 'prop1',
    name: 'My Home',
    type: PropertyType.home,
    createdAt: DateTime(2025, 1, 1),
    modifiedAt: DateTime(2025, 1, 1),
  );

  Widget buildSubject({_FakePolicyController? controller, Policy? existing}) {
    final ctrl = controller ?? _FakePolicyController();
    return ProviderScope(
      overrides: [
        propertiesProvider.overrideWith((_) => Stream.value([property])),
        policyControllerProvider.overrideWith((_) => ctrl),
      ],
      child: MaterialApp(home: PolicyAddEditScreen(existing: existing)),
    );
  }

  group('PolicyAddEditScreen', () {
    testWidgets('shows Add Policy title in add mode', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Add Policy'), findsWidgets);
    });

    testWidgets('shows required provider field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Insurance provider'),
        findsOneWidget,
      );
    });

    testWidgets('shows optional fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Policy number (optional)'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty provider', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Provider is required'), findsOneWidget);
    });

    testWidgets('shows Edit Policy title in edit mode', (tester) async {
      final existing = Policy(
        id: 'pol1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: DateTime(2025, 1, 1),
      );
      await tester.pumpWidget(buildSubject(existing: existing));
      await tester.pumpAndSettle();
      expect(find.text('Edit Policy'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('pre-fills provider in edit mode', (tester) async {
      final existing = Policy(
        id: 'pol1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: DateTime(2025, 1, 1),
      );
      await tester.pumpWidget(buildSubject(existing: existing));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.widgetWithText(TextFormField, 'Insurance provider'),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.controller?.text, 'State Farm');
    });
  });
}
