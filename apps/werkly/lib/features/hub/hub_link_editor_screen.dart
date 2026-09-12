import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-31 — Hub link editor (type chips, label, url, save/delete).
class HubLinkEditorScreen extends ConsumerStatefulWidget {
  const HubLinkEditorScreen({super.key, this.id});

  final String? id;

  static const screenId = ScreenIds.hubLinkEditor;

  @override
  ConsumerState<HubLinkEditorScreen> createState() =>
      _HubLinkEditorScreenState();
}

class _HubLinkEditorScreenState extends ConsumerState<HubLinkEditorScreen> {
  final _labelCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  HubLinkType _type = HubLinkType.url;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _hydrate(Hub hub) {
    if (_loaded) return;
    final id = widget.id;
    if (id != null) {
      final match = hub.links.where((l) => l.id == id);
      if (match.isNotEmpty) {
        final link = match.first;
        _labelCtrl.text = link.label;
        _urlCtrl.text = link.url ?? '';
        _type = link.type;
      }
    }
    _loaded = true;
  }

  Future<void> _save(Hub hub) async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Label ist Pflicht');
      return;
    }
    if ((_type == HubLinkType.url || _type == HubLinkType.social) &&
        _urlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'URL ist für diesen Typ Pflicht');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(hubEditorNotifierProvider.notifier);
    try {
      if (widget.id == null) {
        await notifier.addLink(
          type: _type,
          label: label,
          url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        );
      } else {
        final existing = hub.links.firstWhere((l) => l.id == widget.id);
        await notifier.saveLink(
          existing.copyWith(
            type: _type,
            label: label,
            url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          ),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    setState(() => _busy = true);
    await ref.read(hubEditorNotifierProvider.notifier).deleteLink(id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncHub = ref.watch(hubEditorNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Link hinzufügen' : 'Link bearbeiten'),
        actions: [
          if (widget.id != null)
            IconButton(
              tooltip: 'Löschen',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: asyncHub.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (hub) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _hydrate(hub);
          });
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Typ', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HubLinkType.values.map((t) {
                  return FilterChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://…',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _save(hub),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Speichern'),
              ),
              const SizedBox(height: 12),
              Text(
                'S-31 · ${widget.id ?? 'neu'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
