import 'dart:convert';

import 'package:werkly/features/deals/domain/deal_models.dart';

/// In-memory + optional JSON blob persist for F4 deals.
///
/// Backend table `deals` (soft-delete via deleted_at):
/// // TODO(sync): push/pull Deal.toJson() rows when auth + RLS are wired.
/// // Columns: id, client_id, user_id, brand, title, amount_cents, currency,
/// //   status (inquiry|negotiation|won|invoiced|lost), due_at, notes,
/// //   hub_id, media_kit_id, updated_at, deleted_at
class DealMemoryStore {
  final Map<String, Deal> _byId = {};

  Future<void> Function(String json)? onPersist;
  Future<String?> Function()? onLoad;
  bool _loaded = false;

  Future<void> loadIfNeeded() async {
    if (_loaded) return;
    _loaded = true;
    final loader = onLoad;
    if (loader == null) return;
    final raw = await loader();
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map['deals'] as List? ?? const [];
      for (final e in list) {
        final deal = Deal.fromJson(Map<String, dynamic>.from(e as Map));
        _byId[deal.id] = deal;
      }
    } catch (_) {
      // Corrupt blob — start empty.
    }
  }

  Future<void> _persist() async {
    final cb = onPersist;
    if (cb == null) return;
    // Persist including soft-deleted for sync tombstones.
    final deals = _byId.values.map((d) => d.toJson()).toList();
    await cb(jsonEncode({'deals': deals}));
  }

  /// Active (non-deleted) deals, newest updated first.
  Future<List<Deal>> all({bool includeDeleted = false}) async {
    await loadIfNeeded();
    final list = _byId.values
        .where((d) => includeDeleted || !d.isDeleted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  Future<Deal?> byId(String id, {bool includeDeleted = false}) async {
    await loadIfNeeded();
    final d = _byId[id];
    if (d == null) return null;
    if (!includeDeleted && d.isDeleted) return null;
    return d;
  }

  Future<Deal> upsert(Deal deal) async {
    await loadIfNeeded();
    _byId[deal.id] = deal;
    await _persist();
    return deal;
  }

  /// Soft-delete: set deleted_at (Backend contract). Hard-remove not used.
  Future<Deal?> softDelete(String id) async {
    await loadIfNeeded();
    final existing = _byId[id];
    if (existing == null || existing.isDeleted) return existing;
    final now = DateTime.now().toUtc();
    final deleted = existing.copyWith(deletedAt: now, updatedAt: now);
    _byId[id] = deleted;
    await _persist();
    return deleted;
  }

  Future<void> clear() async {
    _byId.clear();
    await _persist();
  }

  /// Open = active and status ≠ invoiced|lost.
  Future<int> countOpen() async {
    await loadIfNeeded();
    return _byId.values.where((d) => d.isOpen).length;
  }
}
