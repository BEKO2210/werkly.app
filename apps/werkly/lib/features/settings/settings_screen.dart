import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';

/// Screen-ID: S-61 — SettingsScreen · `/more/settings` · settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const screenId = 'S-61';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen (S-61)'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('S-61 · Einstellungen'),
          ),
          ListTile(
            title: const Text('Monetize'),
            subtitle: const Text('S-50'),
            onTap: () => context.push(RoutePaths.monetize),
          ),
          ListTile(
            title: const Text('Paywall'),
            subtitle: const Text('S-60 · 9,99 €/Mo'),
            onTap: () => context.push(RoutePaths.paywall),
          ),
          ListTile(
            title: const Text('Impressum'),
            subtitle: const Text('S-62'),
            onTap: () => context.push(RoutePaths.legalDoc('impressum')),
          ),
          ListTile(
            title: const Text('Datenschutz'),
            subtitle: const Text('S-62'),
            onTap: () => context.push(RoutePaths.legalDoc('privacy')),
          ),
        ],
      ),
    );
  }
}
