import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/presentation/controllers/video_analysis_controller.dart';
import 'package:still_life/features/video_analysis/presentation/screens/processing_screen.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

/// Controller stub whose state is set directly — the screen under test
/// only ever reads it.
class _StubVideoController extends VideoAnalysisController {
  _StubVideoController(super.ref, AnalysisSession? initial) {
    state = initial;
  }
}

Widget _app(AnalysisSession? session) {
  final router = GoRouter(
    initialLocation: '/video/processing',
    routes: [
      GoRoute(
        path: '/video/processing',
        builder: (_, _) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/video/capture',
        builder: (_, _) => const Scaffold(body: Text('capture-screen')),
      ),
      GoRoute(
        path: '/video/review',
        builder: (_, _) => const Scaffold(body: Text('review-screen')),
      ),
      GoRoute(
        path: '/settings/llm',
        builder: (_, _) => const Scaffold(body: Text('llm-settings-screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      videoAnalysisControllerProvider.overrideWith(
        (ref) => _StubVideoController(ref, session),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

AnalysisSession _session({
  AnalysisStatus status = AnalysisStatus.analyzing,
  int selectedFrames = 0,
  AnalysisTier tier = AnalysisTier.localLlm,
  String? failureMessage,
}) => AnalysisSession(
  id: 's-1',
  videoPath: '/tmp/walk.mp4',
  status: status,
  selectedFrames: selectedFrames,
  providerTier: tier,
  startedAt: DateTime(2026),
  failureMessage: failureMessage,
);

void main() {
  testWidgets('a completed-but-empty walkthrough is a terminal state — '
      'never an eternal Searching spinner', (tester) async {
    await tester.pumpWidget(
      _app(_session(status: AnalysisStatus.reviewing, selectedFrames: 3)),
    );
    await tester.pump();

    expect(find.text('Searching for items...'), findsNothing,
        reason: 'the run is over; claiming an ongoing search is a lie');
    expect(find.textContaining('No items found'), findsOneWidget);
  });

  testWidgets('noAiConfigured shows the settings pointer, not a spinner',
      (tester) async {
    await tester.pumpWidget(
      _app(_session(status: AnalysisStatus.noAiConfigured)),
    );
    await tester.pump();

    expect(find.textContaining('No AI provider'), findsOneWidget);
    expect(find.text('Open AI Settings'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Open AI Settings'));
    await tester.pumpAndSettle();
    expect(find.text('llm-settings-screen'), findsOneWidget);
  });

  testWidgets('failed state shows the message and a way back',
      (tester) async {
    await tester.pumpWidget(
      _app(_session(
        status: AnalysisStatus.failed,
        failureMessage: 'ffmpeg rc 1',
      )),
    );
    await tester.pump();

    expect(find.textContaining('ffmpeg rc 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.text('capture-screen'), findsOneWidget);
  });

  testWidgets('cost notice names call count and the local tier posture',
      (tester) async {
    await tester.pumpWidget(
      _app(_session(selectedFrames: 12, tier: AnalysisTier.localLlm)),
    );
    await tester.pump();

    expect(find.textContaining('~12 analysis calls'), findsOneWidget);
    expect(find.textContaining('free'), findsOneWidget);
  });

  testWidgets('cost notice is honest about cloud calls on the user key',
      (tester) async {
    await tester.pumpWidget(
      _app(_session(selectedFrames: 8, tier: AnalysisTier.cloudApi)),
    );
    await tester.pump();

    expect(find.textContaining('~8 analysis calls'), findsOneWidget);
    expect(find.textContaining('your API key'), findsOneWidget);
  });

  testWidgets('no cost notice before frames are selected', (tester) async {
    await tester.pumpWidget(
      _app(_session(
        status: AnalysisStatus.extracting,
        selectedFrames: 0,
      )),
    );
    await tester.pump();

    expect(find.textContaining('analysis calls'), findsNothing);
  });
}
