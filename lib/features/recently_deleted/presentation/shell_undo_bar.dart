import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

import 'undo_providers.dart';

/// The shell's Undo strip, drawn directly above the NavigationBar.
///
/// The NavigationBar below already pads for the gesture area, so the bar's
/// own bottom safe-area padding is removed here; otherwise it would add a
/// band the height of the gesture bar between the two (Furrow 0f28b28).
/// The controller outlives any one screen, so the bar never commits on
/// dispose.
class ShellUndoBar extends ConsumerWidget {
  const ShellUndoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: OhUndoBar(
        controller: ref.watch(shellUndoControllerProvider),
        commitOnDispose: false,
      ),
    );
  }
}
