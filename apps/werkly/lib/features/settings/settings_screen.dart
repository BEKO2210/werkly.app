import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';

/// Screen-ID: S-61 — Settings. RC Pro-Abo ≠ Stripe Creator-Sales.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const screenId = 'S-61';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Dein Pro-Abo'),
            subtitle: Text('Werkly Pro 9,99 €/Mo · RevenueCat / Play'),
          ),
          ListTile(
            title: const Text('Pro freischalten'),
            subtitle: const Text('S-60 · App-Abo, nicht Stripe'),
            onTap: () => context.push(RoutePaths.paywall),
          ),
          const Divider(),
          const ListTile(
            title: Text('Deine Verkäufe'),
            subtitle: Text('Stripe Connect · Creator-Sales (kein App-Abo)'),
          ),
          ListTile(
            title: const Text('Monetize / Stripe'),
            subtitle: const Text('S-50 · Produkt, Tip, Umsätze'),
            onTap: () => context.push(RoutePaths.monetize),
          ),
          const Divider(),
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
