import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/domain/deal_csv.dart';
import 'package:werkly/features/deals/providers/deal_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-42 — DealExportSheet: Pro gate soft; CSV + share/copy; tax disclaimer.
class DealExportScreen extends ConsumerStatefulWidget {
  const DealExportScreen({super.key});

  static const screenId = ScreenIds.dealExport;

  @override
  ConsumerState<DealExportScreen> createState() => _DealExportScreenState();
}

class _DealExportScreenState extends ConsumerState<DealExportScreen> {
  String? _csv;
  bool _busy = false;

  Future<void> _ensureProOrPaywall() async {
    final isPro = ref.read(isProProvider);
    if (shouldSoftGateDealExport(isPro: isPro)) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerDealExport}',
      );
      return;
    }
    await _generate();
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final res =
          await ref.read(dealListNotifierProvider.notifier).exportCsv();
      if (!mounted) return;
      setState(() {
        _csv = res.csv;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _copy() async {
    final csv = _csv;
    if (csv == null) return;
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV in Zwischenablage kopiert')),
    );
  }

  Future<void> _share() async {
    final csv = _csv;
    if (csv == null) return;
    await Share.share(
      csv,
      subject: 'Werkly Deals Export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals exportieren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CSV-Export (Pro)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DealCsv.taxDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spalten: ${DealCsv.columns.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (!isPro) ...[
              FilledButton.icon(
                onPressed: _ensureProOrPaywall,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Mit Pro exportieren'),
              ),
              const SizedBox(height: 8),
              Text(
                'Free: Liste bleibt lesbar — Export freischalten mit Pro.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: _busy ? null : _generate,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.table_chart_outlined),
                label: Text(_csv == null ? 'CSV erzeugen' : 'CSV neu erzeugen'),
              ),
              if (_csv != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy),
                        label: const Text('Kopieren'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Teilen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _csv!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
