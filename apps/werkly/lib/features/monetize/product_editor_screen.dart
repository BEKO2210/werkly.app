import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/monetize_validation.dart';
import 'package:werkly/features/monetize/providers/monetize_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-52 — Product editor: name, price EUR, unlock, live, Hub attach.
class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = ScreenIds.productEditor;

  @override
  ConsumerState<ProductEditorScreen> createState() =>
      _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _unlockCtrl = TextEditingController();
  final _fileCtrl = TextEditingController();
  bool _live = false;
  Product? _existing;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _unlockCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_isNew) {
      setState(() => _loading = false);
      return;
    }
    final p =
        await ref.read(monetizeNotifierProvider.notifier).getProduct(widget.id!);
    if (!mounted) return;
    if (p == null) {
      setState(() {
        _loading = false;
        _error = 'Produkt nicht gefunden';
      });
      return;
    }
    _existing = p;
    _nameCtrl.text = p.name;
    _priceCtrl.text = NumberFormat('#0.##', 'de_DE').format(p.priceCents / 100);
    _unlockCtrl.text = p.unlockUrl ?? '';
    _fileCtrl.text = p.fileLabel ?? '';
    _live = p.live;
    setState(() => _loading = false);
  }

  int? _parsePriceCents() {
    final raw = _priceCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return null;
    return (v * 100).round();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text;
    final cents = _parsePriceCents();
    if (!MonetizeValidation.nameAndPriceOk(name, cents)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name und Preis (EUR) sind Pflicht.')),
      );
      return;
    }
    final home = ref.read(monetizeNotifierProvider).valueOrNull;
    if (home != null && !home.connectStatus.isActive) {
      context.push(RoutePaths.monetizeConnect);
      return;
    }
    if (_isNew) {
      final isPro = ref.read(isProProvider);
      final count = home?.productCount ?? 0;
      if (shouldSoftGateSecondProduct(currentProductCount: count, isPro: isPro)) {
        context.push(
          '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerStripeProducts}',
        );
        return;
      }
    }
    setState(() => _saving = true);
    final notifier = ref.read(monetizeNotifierProvider.notifier);
    final result = _isNew
        ? await notifier.createProduct(
            name: name,
            priceCents: cents!,
            unlockUrl: _unlockCtrl.text,
            fileLabel: _fileCtrl.text,
            live: _live,
          )
        : await notifier.updateProduct(
            existing: _existing!,
            name: name,
            priceCents: cents!,
            unlockUrl: _unlockCtrl.text,
            fileLabel: _fileCtrl.text,
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
        SnackBar(content: Text(_isNew ? 'Produkt gespeichert' : 'Aktualisiert')),
      );
    }
  }

  Future<void> _attachHub() async {
    final product = _existing;
    if (product == null) {
      await _save();
    }
    final products =
        ref.read(monetizeNotifierProvider).valueOrNull?.products ?? const [];
    final p = _existing ?? (products.isEmpty ? null : products.first);
    if (p == null || !mounted) return;
    await ref.read(monetizeNotifierProvider.notifier).attachToHub(
          kind: SaleKind.product,
          refId: p.id,
          label: p.name,
          url: p.unlockUrl,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Am Hub angehängt (Typ Produkt)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produkt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produkt')),
        body: Center(child: Text(_error!)),
      );
    }
    final connect =
        ref.watch(monetizeNotifierProvider).valueOrNull?.connectStatus;
    final canLive = connect?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Neues Produkt' : 'Produkt bearbeiten'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
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
                subtitle: const Text('S-51 — erst verbinden, dann speichern.'),
                onTap: () => context.push(RoutePaths.monetizeConnect),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Preis (EUR) *',
              hintText: '9,99',
              prefixText: '€ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unlockCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Unlock-Link',
              hintText: 'https://…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fileCtrl,
            decoration: const InputDecoration(
              labelText: 'Datei-Label (Mock, kein Upload)',
              hintText: 'guide.pdf',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live'),
            subtitle: Text(
              canLive
                  ? 'Sichtbar für Checkout'
                  : 'Nur mit aktivem Connect',
            ),
            value: _live,
            onChanged: canLive ? (v) => setState(() => _live = v) : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Steuern ggf. selbst abführen. Kein LMS, keine Fan-Abos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isNew ? 'Produkt speichern' : 'Änderungen speichern'),
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
