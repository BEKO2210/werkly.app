import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/ui/widgets/offline_banner.dart';
import 'package:werkly/ui/widgets/quota_banner.dart';

/// Bottom navigation shell: Planen · Texte · Hub · Deals.
/// "Mehr" opens Settings / MoreStack routes (no 5th tab) — Arch §4.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          const QuotaBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Planen',
          ),
          NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes),
            label: 'Texte',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Deals',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Mehr',
        onPressed: () => context.push(RoutePaths.settings),
        child: const Icon(Icons.more_horiz),
      ),
    );
  }
}
