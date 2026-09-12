import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/features/hub/data/hub_file_store.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/data/local_hub_repository.dart';
import 'package:werkly/features/hub/data/public_hub_client.dart';
import 'package:werkly/features/hub/data/track_hub_click_client.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/domain/hub_repository.dart';

/// Local scaffold user id (auth stub).
const kLocalHubUserId = 'local-user';

final hubMemoryStoreProvider = Provider<HubMemoryStore>((ref) {
  final store = HubMemoryStore();
  // Fire-and-forget file attach; memory works without it.
  HubFileStore.attachPersist(store);
  return store;
});

final publicHubClientProvider = Provider<PublicHubClient>((ref) {
  return PublicHubClient(store: ref.watch(hubMemoryStoreProvider));
});

final trackHubClickClientProvider = Provider<TrackHubClickClient>((ref) {
  return TrackHubClickClient(store: ref.watch(hubMemoryStoreProvider));
});

final hubRepositoryProvider = Provider<HubRepository>((ref) {
  return LocalHubRepository(store: ref.watch(hubMemoryStoreProvider));
});

LocalHubRepository _local(Ref ref) =>
    ref.read(hubRepositoryProvider) as LocalHubRepository;

/// Current hub for local user (creates on first watch if missing).
final currentHubProvider = FutureProvider<Hub>((ref) async {
  final repo = _local(ref);
  return repo.getOrCreateHub(userId: kLocalHubUserId);
});

final currentMediaKitProvider = FutureProvider<MediaKit?>((ref) async {
  final hub = await ref.watch(currentHubProvider.future);
  return _local(ref).getMediaKitForHub(hub.id);
});

final hubAnalyticsProvider =
    FutureProvider<List<HubLinkClickStats>>((ref) async {
  final hub = await ref.watch(currentHubProvider.future);
  return _local(ref).linkStats(hub.id);
});

class HubEditorNotifier extends StateNotifier<AsyncValue<Hub>> {
  HubEditorNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  LocalHubRepository get _repo => _local(_ref);

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final hub = await _repo.getOrCreateHub(userId: kLocalHubUserId);
      state = AsyncData(hub);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> saveProfile({
    required String displayName,
    required String bio,
    bool regenerateSlug = false,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final saved = await _repo.updateProfile(
      hub: current,
      displayName: displayName.trim().isEmpty ? current.displayName : displayName,
      bio: bio,
      regenerateSlugFromName: regenerateSlug,
    );
    state = AsyncData(saved);
    _ref.invalidate(currentHubProvider);
  }

  Future<HubGateResult> toggleBranding(bool showBranding) async {
    final current = state.valueOrNull;
    if (current == null) {
      return HubGateResult.paywall();
    }
    final isPro = _ref.read(isProProvider);
    final result = await _repo.setShowBranding(
      hub: current,
      showBranding: showBranding,
      isPro: isPro,
    );
    if (result.ok && result.hub != null) {
      state = AsyncData(result.hub!);
      _ref.invalidate(currentHubProvider);
    }
    return result;
  }

  Future<HubGateResult> setCustomSlug(String raw) async {
    final current = state.valueOrNull;
    if (current == null) return HubGateResult.paywall();
    final isPro = _ref.read(isProProvider);
    final result = await _repo.setCustomSlug(
      hub: current,
      rawSlug: raw,
      isPro: isPro,
    );
    if (result.ok && result.hub != null) {
      state = AsyncData(result.hub!);
      _ref.invalidate(currentHubProvider);
    }
    return result;
  }

  Future<HubLink> addLink({
    required HubLinkType type,
    required String label,
    String? url,
    String? refId,
  }) async {
    final current = state.valueOrNull;
    if (current == null) throw StateError('No hub');
    final link = await _repo.addLink(
      hubId: current.id,
      type: type,
      label: label,
      url: url,
      refId: refId,
    );
    await refresh();
    return link;
  }

  Future<void> saveLink(HubLink link) async {
    await _repo.upsertLink(link);
    await refresh();
  }

  Future<void> deleteLink(String id) async {
    await _repo.deleteLink(id);
    await refresh();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final links = current.orderedLinks;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = links.removeAt(oldIndex);
    links.insert(newIndex, item);
    await _repo.reorderLinks(
      current.id,
      links.map((l) => l.id).toList(),
    );
    await refresh();
  }

  String shareUrl(Hub hub) => _repo.shareUrlFor(hub);

  bool isShareReady(Hub hub) => _repo.isShareReady(hub);
}

final hubEditorNotifierProvider =
    StateNotifierProvider<HubEditorNotifier, AsyncValue<Hub>>((ref) {
  return HubEditorNotifier(ref);
});

class MediaKitNotifier extends StateNotifier<AsyncValue<MediaKit?>> {
  MediaKitNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;
  LocalHubRepository get _repo => _local(_ref);

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final hub = await _repo.getOrCreateHub(userId: kLocalHubUserId);
      final kit = await _repo.getOrCreateMediaKit(hub: hub);
      state = AsyncData(kit);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<MediaKit> save(MediaKit kit) async {
    final saved = await _repo.saveMediaKit(kit);
    state = AsyncData(saved);
    _ref.invalidate(currentMediaKitProvider);
    return saved;
  }

  String shareUrl(MediaKit kit) => _repo.mediaKitShareUrl(kit);
}

final mediaKitNotifierProvider =
    StateNotifierProvider<MediaKitNotifier, AsyncValue<MediaKit?>>((ref) {
  return MediaKitNotifier(ref);
});
