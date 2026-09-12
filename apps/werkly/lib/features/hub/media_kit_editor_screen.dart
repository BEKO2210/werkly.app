import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-32 — Media kit editor (niches, platforms, contact, pitch, share).
class MediaKitEditorScreen extends ConsumerStatefulWidget {
  const MediaKitEditorScreen({super.key});

  static const screenId = ScreenIds.mediaKitEditor;

  @override
  ConsumerState<MediaKitEditorScreen> createState() =>
      _MediaKitEditorScreenState();
}

class _MediaKitEditorScreenState extends ConsumerState<MediaKitEditorScreen> {
  final _nichesCtrl = TextEditingController();
  final _platformCtrl = TextEditingController();
  final _followersCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _link1Ctrl = TextEditingController();
  final _link2Ctrl = TextEditingController();
  final _link3Ctrl = TextEditingController();
  final _pitchCtrl = TextEditingController();
  List<PlatformFollower> _platforms = [];
  String? _kitId;
  bool _hydrated = false;
  bool _busy = false;

  @override
  void dispose() {
    _nichesCtrl.dispose();
    _platformCtrl.dispose();
    _followersCtrl.dispose();
    _mailCtrl.dispose();
    _igCtrl.dispose();
    _link1Ctrl.dispose();
    _link2Ctrl.dispose();
    _link3Ctrl.dispose();
    _pitchCtrl.dispose();
    super.dispose();
  }

  void _hydrate(MediaKit kit) {
    if (_hydrated && _kitId == kit.id) return;
    _kitId = kit.id;
    _hydrated = true;
    _nichesCtrl.text = kit.niches.join(', ');
    _mailCtrl.text = kit.contactMail ?? '';
    _igCtrl.text = kit.contactIg ?? '';
    _pitchCtrl.text = kit.pitch;
    _link1Ctrl.text = kit.exampleLinks.isNotEmpty ? kit.exampleLinks[0] : '';
    _link2Ctrl.text = kit.exampleLinks.length > 1 ? kit.exampleLinks[1] : '';
    _link3Ctrl.text = kit.exampleLinks.length > 2 ? kit.exampleLinks[2] : '';
    setState(() {
      _platforms = List.of(kit.platforms);
    });
  }

  void _addPlatform() {
    final name = _platformCtrl.text.trim();
    final followers = int.tryParse(_followersCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    setState(() {
      _platforms = [..._platforms, PlatformFollower(platform: name, followers: followers)];
      _platformCtrl.clear();
      _followersCtrl.clear();
    });
  }

  Future<void> _save(MediaKit base) async {
    setState(() => _busy = true);
    final niches = _nichesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final links = [
      _link1Ctrl.text.trim(),
      _link2Ctrl.text.trim(),
      _link3Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).take(3).toList();
    final next = base.copyWith(
      niches: niches,
      platforms: _platforms,
      contactMail: _mailCtrl.text.trim().isEmpty ? null : _mailCtrl.text.trim(),
      contactIg: _igCtrl.text.trim().isEmpty ? null : _igCtrl.text.trim(),
      clearContactMail: _mailCtrl.text.trim().isEmpty,
      clearContactIg: _igCtrl.text.trim().isEmpty,
      exampleLinks: links,
      pitch: _pitchCtrl.text.trim(),
    );
    final saved =
        await ref.read(mediaKitNotifierProvider.notifier).save(next);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _kitId = saved.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media Kit gespeichert')),
    );
  }

  Future<void> _share(MediaKit kit) async {
    final url = ref.read(mediaKitNotifierProvider.notifier).shareUrl(kit);
    await Clipboard.setData(ClipboardData(text: url));
    await Share.share('Mein Media Kit: $url', subject: 'Media Kit');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kit-Link kopiert · $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncKit = ref.watch(mediaKitNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Kit'),
        actions: [
          asyncKit.maybeWhen(
            data: (kit) => kit == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Teilen',
                    onPressed: () => _share(kit),
                    icon: const Icon(Icons.ios_share),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncKit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (kit) {
          if (kit == null) {
            return const Center(child: Text('Kein Media Kit'));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _hydrate(kit);
          });
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nichesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nischen (kommagetrennt)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Plattformen + Follower (manuell)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _platformCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plattform',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _followersCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Follower',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    onPressed: _addPlatform,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              ..._platforms.asMap().entries.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.value.platform),
                      subtitle: Text('${e.value.followers} Follower'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _platforms = List.of(_platforms)..removeAt(e.key);
                        }),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              TextField(
                controller: _mailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kontakt E-Mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _igCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kontakt IG',
                  border: OutlineInputBorder(),
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _link1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Beispiel-Link 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _link2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Beispiel-Link 2 (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _link3Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Beispiel-Link 3 (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pitchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kurz-Pitch',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 400,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () => _save(kit),
                child: Text(_busy ? 'Speichern…' : 'Speichern'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _share(kit),
                icon: const Icon(Icons.link),
                label: const Text('Kit-Link teilen / kopieren'),
              ),
              const SizedBox(height: 16),
              Text(
                'S-32 · publicSlug: ${kit.publicSlug ?? '—'}',
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
