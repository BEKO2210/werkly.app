import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/features/hub/data/local_hub_repository.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/hub/providers/hub_providers.dart';
import 'package:werkly/features/monetize/data/local_monetize_repository.dart';
import 'package:werkly/features/monetize/data/monetize_file_store.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/data/orders_client.dart';
import 'package:werkly/features/monetize/data/stripe_checkout_client.dart';
import 'package:werkly/features/monetize/data/stripe_connect_client.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/monetize_repository.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

final monetizeMemoryStoreProvider = Provider<MonetizeMemoryStore>((ref) {
  final store = MonetizeMemoryStore();
  MonetizeFileStore.attachPersist(store);
  return store;
});

final monetizeRepositoryProvider = Provider<MonetizeRepository>((ref) {
  return LocalMonetizeRepository(store: ref.watch(monetizeMemoryStoreProvider));
});

final stripeConnectClientProvider = Provider<StripeConnectClient>((ref) {
  final client = StripeConnectClient();
  client.bindStore(ref.watch(monetizeMemoryStoreProvider));
  return client;
});

final stripeCheckoutClientProvider = Provider<StripeCheckoutClient>((ref) {
  final client = StripeCheckoutClient();
  client.bindStore(ref.watch(monetizeMemoryStoreProvider));
  return client;
});

final ordersClientProvider = Provider<OrdersClient>((ref) {
  final client = OrdersClient();
  client.bindStore(ref.watch(monetizeMemoryStoreProvider));
  return client;
});

LocalMonetizeRepository _local(Ref ref) =>
    ref.read(monetizeRepositoryProvider) as LocalMonetizeRepository;

class MonetizeHomeState {
  const MonetizeHomeState({
    required this.connectStatus,
    required this.products,
    required this.tips,
    required this.sales,
  });

  final ConnectStatus connectStatus;
  final List<Product> products;
  final List<TipLink> tips;
  final List<Sale> sales;

  int get productCount => products.length;
  int get liveProductCount => products.where((p) => p.live).length;
  bool get hasLiveTip => tips.any((t) => t.live);
  int get offerCount => products.length + tips.length;
}

class MonetizeNotifier extends StateNotifier<AsyncValue<MonetizeHomeState>> {
  MonetizeNotifier(this._ref) : super(const AsyncLoading()) {
    refresh();
  }

  final Ref _ref;

  LocalMonetizeRepository get _repo => _local(_ref);

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final snap = await _repo.snapshot();
      final orders = await _ref.read(ordersClientProvider).listOrders();
      state = AsyncData(
        MonetizeHomeState(
          connectStatus: snap.connectStatus,
          products: snap.products,
          tips: snap.tips,
          sales: orders,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<ConnectOnboardResponse> startOnboard() async {
    final res = await _ref.read(stripeConnectClientProvider).startOnboard();
    await refresh();
    return res;
  }

  Future<ConnectStatus> refreshConnect() async {
    final status = await _ref.read(stripeConnectClientProvider).refreshStatus();
    await refresh();
    return status;
  }

  Future<MonetizeGateResult<Product>> createProduct({
    required String name,
    required int priceCents,
    String? unlockUrl,
    String? fileLabel,
    bool live = false,
  }) async {
    final result = await _repo.createProduct(
      name: name,
      priceCents: priceCents,
      unlockUrl: unlockUrl,
      fileLabel: fileLabel,
      live: live,
      isPro: _ref.read(isProProvider),
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<MonetizeGateResult<Product>> updateProduct({
    required Product existing,
    required String name,
    required int priceCents,
    String? unlockUrl,
    String? fileLabel,
    required bool live,
  }) async {
    final result = await _repo.updateProduct(
      existing: existing,
      name: name,
      priceCents: priceCents,
      unlockUrl: unlockUrl,
      fileLabel: fileLabel,
      live: live,
      isPro: _ref.read(isProProvider),
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<MonetizeGateResult<TipLink>> saveTip({
    TipLink? existing,
    String label = 'Tip',
    List<int> suggestedAmountsCents = const [300, 500, 1000],
    required bool live,
  }) async {
    final result = await _repo.saveTip(
      existing: existing,
      label: label,
      suggestedAmountsCents: suggestedAmountsCents,
      live: live,
      isPro: _ref.read(isProProvider),
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<Product?> getProduct(String id) => _repo.getProduct(id);

  Future<TipLink?> getTip(String id) => _repo.getTip(id);

  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final res = await _ref.read(stripeCheckoutClientProvider).checkout(
          request: request,
          isPro: _ref.read(isProProvider),
        );
    await refresh();
    return res;
  }

  /// Local stand-in for webhook-written `orders` (client remains GET-only).
  Future<Sale> simulateSale({
    SaleKind kind = SaleKind.product,
    int amountCents = 999,
    String? offerId,
    String? label,
  }) async {
    final sale = await _repo.simulateSale(
      kind: kind,
      amountCents: amountCents,
      offerId: offerId,
      label: label,
      isPro: _ref.read(isProProvider),
    );
    await refresh();
    return sale;
  }

  /// Create or update HubLink type product|tip with [refId].
  Future<HubLink> attachToHub({
    required SaleKind kind,
    required String refId,
    required String label,
    String? url,
  }) async {
    final hub = await _ref
        .read(hubRepositoryProvider)
        .getOrCreateHub(userId: kLocalHubUserId);
    final type =
        kind == SaleKind.product ? HubLinkType.product : HubLinkType.tip;
    final existing = hub.links.where((l) => l.type == type && l.refId == refId);
    final local = _ref.read(hubRepositoryProvider);
    if (existing.isNotEmpty) {
      final updated = existing.first.copyWith(label: label, url: url);
      await local.upsertLink(updated);
      _ref.invalidate(hubEditorNotifierProvider);
      _ref.invalidate(currentHubProvider);
      return updated;
    }
    final added = await (local as LocalHubRepository).addLink(
      hubId: hub.id,
      type: type,
      label: label,
      url: url,
      refId: refId,
    );
    _ref.invalidate(hubEditorNotifierProvider);
    _ref.invalidate(currentHubProvider);
    return added;
  }
}

final monetizeNotifierProvider =
    StateNotifierProvider<MonetizeNotifier, AsyncValue<MonetizeHomeState>>(
        (ref) {
  return MonetizeNotifier(ref);
});
