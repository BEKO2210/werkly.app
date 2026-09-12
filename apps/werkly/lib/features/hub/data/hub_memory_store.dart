import 'dart:convert';

import 'package:werkly/features/hub/domain/hub_models.dart';

/// In-memory + optional JSON blob persist hook for F3 hubs.
class HubMemoryStore {
  Hub? _hub;
  MediaKit? _kit;
  final Map<String, List<HubLinkClickStats>> _stats = {};
  /// Raw click timestamps per hub_link_id (local track-hub-click mock).
  final Map<String, List<DateTime>> _clicksByLinkId = {};

  /// Optional persist callback (file / sqlite bridge).
  Future<void> Function(String json)? onPersist;
  Future<String?> Function()? onLoad;

  Hub? get hub => _hub;
  MediaKit? get kit => _kit;

  Future<void> loadIfNeeded() async {
    if (_hub != null) return;
    final loader = onLoad;
    if (loader == null) return;
    final raw = await loader();
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['hub'] != null) {
        _hub = Hub.fromJson(Map<String, dynamic>.from(map['hub'] as Map));
      }
      if (map['media_kit'] != null) {
        _kit = MediaKit.fromJson(
          Map<String, dynamic>.from(map['media_kit'] as Map),
        );
      }
    } catch (_) {
      // Corrupt blob — start empty.
    }
  }

  Future<void> _persist() async {
    final cb = onPersist;
    if (cb == null) return;
    await cb(
      jsonEncode({
        'hub': _hub?.toJson(),
        'media_kit': _kit?.toJson(),
      }),
    );
  }

  Future<Hub?> getHub() async {
    await loadIfNeeded();
    return _hub;
  }

  Future<Hub?> bySlug(String slug) async {
    await loadIfNeeded();
    if (_hub == null) return null;
    if (_hub!.slug == slug && _hub!.isPublic) return _hub;
    return null;
  }

  Future<Set<String>> takenSlugs() async {
    await loadIfNeeded();
    final set = <String>{};
    if (_hub != null) set.add(_hub!.slug);
    if (_kit?.publicSlug != null) set.add(_kit!.publicSlug!);
    return set;
  }

  Future<Hub> upsertHub(Hub hub) async {
    await loadIfNeeded();
    _hub = hub;
    await _persist();
    return hub;
  }

  Future<void> clear() async {
    _hub = null;
    _kit = null;
    _stats.clear();
    _clicksByLinkId.clear();
    await _persist();
  }

  Future<MediaKit?> getKit() async {
    await loadIfNeeded();
    return _kit;
  }

  Future<MediaKit> upsertKit(MediaKit kit) async {
    await loadIfNeeded();
    _kit = kit;
    await _persist();
    return kit;
  }

  Future<void> recordClick(String hubLinkId, {DateTime? at}) async {
    final t = at ?? DateTime.now().toUtc();
    _clicksByLinkId.putIfAbsent(hubLinkId, () => []).add(t);
  }

  int clicksSince(String hubLinkId, Duration window, {DateTime? now}) {
    final n = now ?? DateTime.now().toUtc();
    final cutoff = n.subtract(window);
    final list = _clicksByLinkId[hubLinkId] ?? const [];
    return list.where((t) => !t.isBefore(cutoff)).length;
  }

  Future<void> setFakeStats(String hubId, List<HubLinkClickStats> stats) async {
    _stats[hubId] = stats;
  }

  Future<List<HubLinkClickStats>> statsFor(String hubId) async {
    if (_stats.containsKey(hubId)) {
      return List.unmodifiable(_stats[hubId]!);
    }
    await loadIfNeeded();
    final hub = _hub;
    if (hub == null || hub.id != hubId) return const [];
    final now = DateTime.now().toUtc();
    return hub.orderedLinks
        .map(
          (l) => HubLinkClickStats(
            linkId: l.id,
            label: l.label,
            clicks7d: clicksSince(l.id, const Duration(days: 7), now: now),
            clicks30d: clicksSince(l.id, const Duration(days: 30), now: now),
          ),
        )
        .toList();
  }
}
