import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/recently_deleted/presentation/shell_undo_bar.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo for deletes whose screen closed (item, room) or that ran on
          // a tab (bulk delete). No timer; see shellUndoControllerProvider.
          const ShellUndoBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Inventory',
              ),
              NavigationDestination(
                icon: Icon(Icons.room_preferences_outlined),
                selectedIcon: Icon(Icons.room_preferences),
                label: 'Rooms',
              ),
              NavigationDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: 'Reports',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
