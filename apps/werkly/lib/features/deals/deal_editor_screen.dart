import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/domain/deal_csv.dart';
import 'package:werkly/features/deals/data/local_deal_repository.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/domain/deal_validation.dart';
import 'package:werkly/features/deals/providers/deal_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-41 — Deal editor: fields + status pipeline chips + soft gate.
class DealEditorScreen extends ConsumerStatefulWidget {
  const DealEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = ScreenIds.dealEditor;

  @override
  ConsumerState<DealEditorScreen> createState() => _DealEditorScreenState();
}

class _DealEditorScreenState extends ConsumerState<DealEditorScreen> {
  final _brandCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DealStatus _status = DealStatus.inquiry;
  DateTime? _dueAt;
  Deal? _existing;
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
    _brandCtrl.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_isNew) {
      setState(() => _loading = false);
      return;
    }
    final deal =
        await ref.read(dealListNotifierProvider.notifier).getById(widget.id!);
    if (!mounted) return;
    if (deal == null) {
      setState(() {
        _loading = false;
        _error = 'Deal nicht gefunden';
      });
      return;
    }
    _existing = deal;
    _brandCtrl.text = deal.brand;
    _titleCtrl.text = deal.title;
    if (deal.amountCents != null) {
      _amountCtrl.text =
          NumberFormat('#0.##', 'de_DE').format(deal.amountCents! / 100);
    }
    _notesCtrl.text = deal.notes ?? '';
    _status = deal.status;
    _dueAt = deal.dueAt;
    setState(() => _loading = false);
  }

  int? _parseAmountCents() {
    final raw = _amountCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return null;
    return (v * 100).round();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt?.toLocal() ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('de', 'DE'),
    );
    if (picked == null) return;
    setState(() => _dueAt = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final brand = _brandCtrl.text;
    final title = _titleCtrl.text;
    if (!DealValidation.brandAndTitleOk(brand, title)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marke und Titel sind Pflichtfelder.')),
      );
      return;
    }

    // Soft-gate before create when Free already at 5 open.
    if (_isNew) {
      final listState = ref.read(dealListNotifierProvider).valueOrNull;
      final open = listState?.openCount ?? 0;
      final isPro = ref.read(isProProvider);
      if (shouldSoftGateDealCreate(open, isPro: isPro) && _status.isOpen) {
        context.push(
          '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerDeals}',
        );
        return;
      }
    }

    setState(() => _saving = true);
    final amountCents = _parseAmountCents();
    final notifier = ref.read(dealListNotifierProvider.notifier);
    final DealGateResult result;
    if (_isNew) {
      result = await notifier.create(
        brand: brand,
        title: title,
        amountCents: amountCents,
        status: _status,
        dueAt: _dueAt,
        notes: _notesCtrl.text,
      );
    } else {
      result = await notifier.update(
        existing: _existing!,
        brand: brand,
        title: title,
        amountCents: amountCents,
        clearAmount: amountCents == null,
        status: _status,
        dueAt: _dueAt,
        clearDueAt: _dueAt == null,
        notes: _notesCtrl.text,
        clearNotes: _notesCtrl.text.trim().isEmpty,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${result.trigger ?? QuotaPolicy.paywallTriggerDeals}',
      );
      return;
    }
    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNew ? 'Deal angelegt' : 'Deal gespeichert'),
        ),
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deal löschen?'),
        content: Text('„${_existing!.brand} · ${_existing!.title}“ entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(dealListNotifierProvider.notifier).delete(_existing!.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isNew ? 'Neuer Deal' : 'Deal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal')),
        body: Center(child: Text(_error!)),
      );
    }

    final dueLabel = _dueAt == null
        ? 'Fällig am…'
        : DateFormat('dd.MM.yyyy', 'de_DE').format(_dueAt!.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Neuer Deal' : 'Deal bearbeiten'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Löschen',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
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
          TextField(
            controller: _brandCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Marke / Brand *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titel *',
              hintText: 'z. B. Sommerkampagne Reel',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Betrag (EUR)',
              hintText: '0,00',
              prefixText: '€ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Status-Pipeline',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DealStatus.pipeline.map((s) {
              final selected = _status == s;
              return ChoiceChip(
                label: Text(s.labelDe),
                selected: selected,
                onSelected: (_) => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(dueLabel),
            trailing: _dueAt == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dueAt = null),
                  ),
            onTap: _pickDue,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notizen',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            DealCsv.taxDisclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isNew ? 'Deal anlegen' : 'Änderungen speichern'),
          ),
        ],
      ),
    );
  }
}
