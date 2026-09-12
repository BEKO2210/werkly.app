import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-30 — Hub editor (profile, reorderable links, share, soft gates).
class HubEditorScreen extends ConsumerStatefulWidget {
  const HubEditorScreen({super.key});

  static const screenId = ScreenIds.hubEditor;

  @override
  ConsumerState<HubEditorScreen> createState() => _HubEditorScreenState();
}

class _HubEditorScreenState extends ConsumerState<HubEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  String? _boundHubId;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(Hub hub) {
    if (_boundHubId != hub.id) {
      _boundHubId = hub.id;
      _nameCtrl.text = hub.displayName;
      _bioCtrl.text = hub.bio;
      _slugCtrl.text = hub.slug;
      return;
    }
    if (_slugCtrl.text != hub.slug) {
      _slugCtrl.text = hub.slug;
    }
  }

  Future<void> _persistProfile({bool regenerateSlug = false}) async {
    setState(() => _saving = true);
    await ref.read(hubEditorNotifierProvider.notifier).saveProfile(
          displayName: _nameCtrl.text,
          bio: _bioCtrl.text,
          regenerateSlug: regenerateSlug,
        );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _share(Hub hub) async {
    final notifier = ref.read(hubEditorNotifierProvider.notifier);
    if (!notifier.isShareReady(hub)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mindestens einen Link hinzufügen, bevor du teilst.'),
        ),
      );
      return;
    }
    final url = notifier.shareUrl(hub);
    await Clipboard.setData(ClipboardData(text: url));
    await Share.share(
      'Mein Werkly Hub: $url',
      subject: hub.displayName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link kopiert · $url')),
    );
  }

  Future<void> _copyLink(Hub hub) async {
    final url = ref.read(hubEditorNotifierProvider.notifier).shareUrl(hub);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kopiert: $url')),
    );
  }

  Future<void> _onBrandingToggle(bool value, Hub hub) async {
    // value == true means show branding; false = branding off (Pro).
    final result = await ref
        .read(hubEditorNotifierProvider.notifier)
        .toggleBranding(value);
    if (!mounted) return;
    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerHubBranding}',
      );
    }
  }

  Future<void> _onCustomSlugSubmit() async {
    final result = await ref
        .read(hubEditorNotifierProvider.notifier)
        .setCustomSlug(_slugCtrl.text);
    if (!mounted) return;
    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerHubBranding}',
      );
      return;
    }
    if (result.hub != null) {
      _slugCtrl.text = result.hub!.slug;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Slug: ${result.hub!.slug}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncHub = ref.watch(hubEditorNotifierProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub'),
        actions: [
          IconButton(
            tooltip: 'Analytics',
            onPressed: () => context.push(RoutePaths.hubAnalytics),
            icon: const Icon(Icons.bar_chart_outlined),
          ),
          IconButton(
            tooltip: 'Vorschau',
            onPressed: () => context.push(RoutePaths.hubPreview),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: asyncHub.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (hub) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _syncControllers(hub);
          });
          final shareUrl =
              ref.read(hubEditorNotifierProvider.notifier).shareUrl(hub);
          final ready =
              ref.read(hubEditorNotifierProvider.notifier).isShareReady(hub);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: hub.avatarUrl == null
                        ? Text(
                            hub.displayName.isNotEmpty
                                ? hub.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Avatar-Platzhalter\n(Upload später)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    _persistProfile(regenerateSlug: !isPro),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kurz-Bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 160,
                onEditingComplete: _persistProfile,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Öffentliche URL'),
                subtitle: SelectableText(shareUrl),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyLink(hub),
                ),
              ),
              const Divider(),
              Text(
                'Slug & Branding',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _slugCtrl,
                enabled: true,
                decoration: InputDecoration(
                  labelText: 'Slug',
                  border: const OutlineInputBorder(),
                  prefixText: 'werkly.app/h/',
                  suffixIcon: isPro
                      ? null
                      : const Icon(Icons.lock_outline, size: 18),
                  helperText: isPro
                      ? 'Pro: Custom Slug speichern'
                      : 'Free: Auto-Slug · Custom = Pro',
                ),
                onTap: isPro
                    ? null
                    : () {
                        context.push(
                          '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerHubBranding}',
                        );
                      },
                onSubmitted: (_) {
                  if (isPro) {
                    _onCustomSlugSubmit();
                  } else {
                    context.push(
                      '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerHubBranding}',
                    );
                  }
                },
              ),
              if (isPro) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _onCustomSlugSubmit,
                    child: const Text('Slug speichern'),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Powered by Werkly'),
                subtitle: Text(
                  hub.showBranding
                      ? 'Branding sichtbar (Free)'
                      : 'Branding aus (Pro)',
                ),
                value: hub.showBranding,
                onChanged: (v) {
                  if (!isPro && !v) {
                    context.push(
                      '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerHubBranding}',
                    );
                    return;
                  }
                  _onBrandingToggle(v, hub);
                },
              ),
              if (hub.showBranding)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Footer-Preview: Powered by Werkly',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Links',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push(RoutePaths.hubLink),
                    icon: const Icon(Icons.add),
                    label: const Text('Link'),
                  ),
                ],
              ),
              if (hub.links.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.link_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Erster Link = Bio fertig',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Füge einen Link hinzu, dann teilen.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.hubLink),
                        icon: const Icon(Icons.add),
                        label: const Text('Ersten Link hinzufügen'),
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hub.orderedLinks.length,
                  onReorder: (o, n) => ref
                      .read(hubEditorNotifierProvider.notifier)
                      .reorder(o, n),
                  itemBuilder: (context, index) {
                    final link = hub.orderedLinks[index];
                    return ListTile(
                      key: ValueKey(link.id),
                      leading: Icon(_iconFor(link.type)),
                      title: Text(link.label),
                      subtitle: Text(
                        [
                          link.type.label,
                          if (link.url != null && link.url!.isNotEmpty)
                            link.url!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.drag_handle),
                      onTap: () =>
                          context.push(RoutePaths.hubLinkId(link.id)),
                    );
                  },
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: ready ? () => _share(hub) : null,
                icon: const Icon(Icons.ios_share),
                label: Text(ready ? 'Teilen' : 'Teilen (Link fehlt)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copyLink(hub),
                icon: const Icon(Icons.link),
                label: const Text('Link kopieren'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(RoutePaths.hubPreview),
                icon: const Icon(Icons.phone_iphone),
                label: const Text('Vorschau öffnen'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(RoutePaths.hubMediaKit),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Media Kit'),
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 24),
              Text(
                'S-30 · Free: 1 Hub + Branding · Pro: Custom Slug + Branding aus',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(HubLinkType t) => switch (t) {
        HubLinkType.url => Icons.link,
        HubLinkType.social => Icons.alternate_email,
        HubLinkType.mediaKit => Icons.description_outlined,
        HubLinkType.product => Icons.shopping_bag_outlined,
        HubLinkType.tip => Icons.favorite_outline,
      };
}
