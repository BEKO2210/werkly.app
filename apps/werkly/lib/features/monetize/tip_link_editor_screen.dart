import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/providers/monetize_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-53 — Tip editor: suggested amounts, live, Hub attach.
class TipLinkEditorScreen extends ConsumerStatefulWidget {
  const TipLinkEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = ScreenIds.tipLinkEditor;

  @override
  ConsumerState<TipLinkEditorScreen> createState() =>
      _TipLinkEditorScreenState();
}

class _TipLinkEditorScreenState extends ConsumerState<TipLinkEditorScreen> {
  final _labelCtrl = TextEditingController(text: 'Tip');
  final _customCtrl = TextEditingController();
  List<int> _amounts = const [300, 500, 1000];
  bool _live = false;
  TipLink? _existing;
  bool _loading = true;
  bool _saving = false;

  static final _eur = NumberFormat.currency(
    locale: 'de_DE',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.id;
    TipLink? tip;
    if (id != null) {
      tip = await ref.read(monetizeNotifierProvider.notifier).getTip(id);
    } else {
      final tips =
          ref.read(monetizeNotifierProvider).valueOrNull?.tips ?? const [];
      if (tips.isNotEmpty) tip = tips.first;
    }
    if (!mounted) return;
    if (tip != null) {
      _existing = tip;
      _labelCtrl.text = tip.label;
      _amounts = List<int>.from(tip.suggestedAmountsCents);
      _live = tip.live;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final home = ref.read(monetizeNotifierProvider).valueOrNull;
    if (home != null && !home.connectStatus.isActive) {
      context.push(RoutePaths.monetizeConnect);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(monetizeNotifierProvider.notifier).saveTip(
          existing: _existing,
          label: _labelCtrl.text,
          suggestedAmountsCents: _amounts,
          live: _live,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.connectRequired) {
      context.push(RoutePaths.monetizeConnect);
      return;
    }
    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${result.trigger ?? QuotaPolicy.paywallTriggerStripeProducts}',
      );
      return;
    }
    if (result.ok) {
      _existing = result.value;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip-Link gespeichert')),
      );
    }
  }

  Future<void> _attachHub() async {
    if (_existing == null) await _save();
    final tip = _existing;
    if (tip == null || !mounted) return;
    await ref.read(monetizeNotifierProvider.notifier).attachToHub(
          kind: SaleKind.tip,
          refId: tip.id,
          label: tip.label,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Am Hub angehängt (Typ Tip)')),
    );
  }

  void _addCustom() {
    final raw = _customCtrl.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null) return;
    final cents = (v * 100).round();
    if (cents < QuotaPolicy.minTipAmountCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 1,00 €')),
      );
      return;
    }
    setState(() {
      if (!_amounts.contains(cents)) {
        _amounts = [..._amounts, cents]..sort();
      }
      _customCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tip-Link')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final canLive = ref.watch(monetizeNotifierProvider).valueOrNull
            ?.connectStatus
            .isActive ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tip-Link'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canLive)
            Card(
              child: ListTile(
                leading: const Icon(Icons.link_off),
                title: const Text('Stripe Connect nicht aktiv'),
                onTap: () => context.push(RoutePaths.monetizeConnect),
              ),
            ),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Betragsvorschläge', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _amounts
                .map(
                  (c) => InputChip(
                    label: Text(_eur.format(c / 100)),
                    onDeleted: () => setState(() {
                      _amounts = _amounts.where((e) => e != c).toList();
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Eigener Betrag EUR',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addCustom,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live'),
            value: _live,
            onChanged: canLive ? (v) => setState(() => _live = v) : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Free: Tip oder 1 Produkt (XOR). Steuern ggf. selbst abführen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Tip speichern'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _attachHub,
            icon: const Icon(Icons.hub_outlined),
            label: const Text('An Hub anhängen'),
          ),
        ],
      ),
    );
  }
}
