import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/providers/monetize_providers.dart';
import 'package:werkly/features/monetize/widgets/connect_status_card.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-51 — Stripe Connect onboard + refresh after return.
class StripeConnectScreen extends ConsumerStatefulWidget {
  const StripeConnectScreen({super.key});

  static const screenId = ScreenIds.stripeConnect;

  @override
  ConsumerState<StripeConnectScreen> createState() =>
      _StripeConnectScreenState();
}

class _StripeConnectScreenState extends ConsumerState<StripeConnectScreen> {
  bool _busy = false;
  String? _lastUrl;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final res =
          await ref.read(monetizeNotifierProvider.notifier).startOnboard();
      _lastUrl = res.url;
      final uri = Uri.tryParse(res.url);
      if (uri != null) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mock-URL: ${res.url}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final status =
          await ref.read(monetizeNotifierProvider.notifier).refreshConnect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: ${status.labelDe}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monetizeNotifierProvider);
    final status = async.valueOrNull?.connectStatus ?? ConnectStatus.none;
    final cta = switch (status) {
      ConnectStatus.none => 'Stripe verbinden',
      ConnectStatus.pending => 'Onboarding fortsetzen',
      ConnectStatus.active => 'Dashboard öffnen (Mock)',
      ConnectStatus.restricted => 'Onboarding erneut starten',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Stripe Connect')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConnectStatusCard(status: status),
          const SizedBox(height: 16),
          const Text(
            'Auszahlungen laufen auf dein Stripe-Konto. '
            'Checkout und Live-Angebote nur bei Status „Aktiv“.',
          ),
          const SizedBox(height: 8),
          Text(
            'App-Abo (Werkly Pro 9,99 €/Mo) ≠ Creator-Sales (Stripe).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _start,
            icon: const Icon(Icons.open_in_new),
            label: Text(cta),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Status aktualisieren'),
          ),
          if (_lastUrl != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              _lastUrl!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 24),
          Text(
            'Mock: ohne Edge setzt Refresh pending → active. '
            'Keine Stripe-Secrets in der App.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
