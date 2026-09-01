import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Still Life's one failure state for a screen whose data did not load: the
/// fleet's [OhErrorState] (a plain sentence, Try again, the exception only
/// behind Details). The exception is logged, never printed as the message.
Widget loadFailure(
  Object error,
  StackTrace? stackTrace, {
  required String title,
  VoidCallback? onRetry,
}) {
  debugPrint('Still Life: $title: $error');
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(OhSpacing.md),
      child: OhErrorState.fromError(
        error,
        stackTrace: stackTrace,
        title: title,
        onRetry: onRetry,
        icon: Icons.error_outline,
      ),
    ),
  );
}

/// The one-line form for a small slot (a card, a dropdown) where a full
/// [OhErrorState] would not fit: says what didn't load, in plain words.
Widget inlineLoadFailure(Object error, {required String what}) {
  debugPrint('Still Life: $what: $error');
  return Text(what);
}

/// A plain sentence for an action that failed: what didn't happen, then the
/// fleet's friendly reason. The raw error is logged, not shown.
String failureSentence(String what, Object error) {
  debugPrint('Still Life: $what: $error');
  return '$what. ${ohFriendlyErrorMessage(error)}';
}

/// Shows [failureSentence] in a SnackBar.
void showFailureSnack(BuildContext context, String what, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(failureSentence(what, error))));
}
