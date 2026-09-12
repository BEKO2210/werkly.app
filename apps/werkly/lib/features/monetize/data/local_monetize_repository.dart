import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/monetize_repository.dart';
import 'package:werkly/features/monetize/domain/monetize_validation.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

/// Soft-gate / connect-block result for product / tip mutate.
class MonetizeGateResult<T> {
  const MonetizeGateResult._({
    this.value,
    this.softGated = false,
    this.connectRequired = false,
    this.trigger,
    this.error,
  });

  final T? value;
  final bool softGated;
  final bool connectRequired;
  final String? trigger;
  final StripeApiError? error;

  bool get ok => value != null && !softGated && !connectRequired;

  factory MonetizeGateResult.ok(T value) => MonetizeGateResult._(value: value);

  factory MonetizeGateResult.paywall() => MonetizeGateResult._(
        softGated: true,
        trigger: QuotaPolicy.paywallTriggerStripeProducts,
        error: StripeApiError.fromJson(
          StripeMockFixtures.checkout402,
          httpStatus: 402,
        ),
      );

  factory MonetizeGateResult.connect() => MonetizeGateResult._(
        connectRequired: true,
        error: StripeApiError.fromJson(
          StripeMockFixtures.checkout403,
          httpStatus: 403,
        ),
      );
}

class LocalMonetizeRepository implements MonetizeRepository {
  LocalMonetizeRepository({
    required MonetizeMemoryStore store,
    Uuid? uuid,
  })  : _store = store,
        _uuid = uuid ?? const Uuid();

  final MonetizeMemoryStore _store;
  final Uuid _uuid;

  MonetizeMemoryStore get store => _store;

  @override
  Future<ConnectStatus> connectStatus() => _store.connectStatus();

  @override
  Future<ConnectStatus> setConnectStatus(ConnectStatus status) =>
      _store.setConnectStatus(status);

  @override
  Future<List<Product>> listProducts() => _store.products();

  @override
  Future<Product?> getProduct(String id) => _store.productById(id);

  @override
  Future<Product> upsertProduct(Product product) async {
    final updated = product.copyWith(updatedAt: DateTime.now().toUtc());
    return _store.upsertProduct(updated);
  }

  @override
  Future<void> deleteProduct(String id) => _store.deleteProduct(id);

  @override
  Future<List<TipLink>> listTips() => _store.tips();

  @override
  Future<TipLink?> getTip(String id) => _store.tipById(id);

  @override
  Future<TipLink> upsertTip(TipLink tip) async {
    final updated = tip.copyWith(updatedAt: DateTime.now().toUtc());
    return _store.upsertTip(updated);
  }

  @override
  Future<void> deleteTip(String id) => _store.deleteTip(id);

  @override
  Future<List<Sale>> listSales() => _store.sales();

  @override
  Future<Sale> addSale(Sale sale) => _store.addSale(sale);

  @override
  Future<MonetizeSnapshot> snapshot() => _store.snapshot();

  /// Create product; Free soft-gates a 2nd product. Live requires Connect active.
  Future<MonetizeGateResult<Product>> createProduct({
    required String name,
    required int priceCents,
    String? unlockUrl,
    String? fileLabel,
    bool live = false,
    required bool isPro,
  }) async {
    final snap = await snapshot();
    if (MonetizeValidation.requiresConnect(snap.connectStatus)) {
      return MonetizeGateResult.connect();
    }
    if (MonetizeValidation.wouldExceedXorOfferCreate(
      isPro: isPro,
      productCount: snap.products.length,
      tipCount: snap.tips.length,
      creating: SaleKind.product,
      isNew: true,
    )) {
      return MonetizeGateResult.paywall();
    }
    if (MonetizeValidation.wouldExceedProductCreateLimit(
      isPro: isPro,
      currentProductCount: snap.products.length,
    )) {
      return MonetizeGateResult.paywall();
    }
    if (live &&
        MonetizeValidation.wouldExceedLiveOfferLimit(
          isPro: isPro,
          liveProductCount: snap.liveProductCount,
          hasLiveTip: snap.hasLiveTip,
          nextKind: SaleKind.product,
          nextIsLive: true,
          wasAlreadyLive: false,
        )) {
      return MonetizeGateResult.paywall();
    }
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final product = Product(
      id: id,
      name: name.trim(),
      priceCents: priceCents,
      unlockUrl: unlockUrl?.trim().isEmpty == true ? null : unlockUrl?.trim(),
      fileLabel: fileLabel?.trim().isEmpty == true ? null : fileLabel?.trim(),
      live: live,
      createdAt: now,
      updatedAt: now,
    );
    final saved = await upsertProduct(product);
    return MonetizeGateResult.ok(saved);
  }

  Future<MonetizeGateResult<Product>> updateProduct({
    required Product existing,
    required String name,
    required int priceCents,
    String? unlockUrl,
    String? fileLabel,
    required bool live,
    required bool isPro,
  }) async {
    final snap = await snapshot();
    if (MonetizeValidation.requiresConnect(snap.connectStatus)) {
      return MonetizeGateResult.connect();
    }
    if (MonetizeValidation.wouldExceedLiveOfferLimit(
      isPro: isPro,
      liveProductCount: snap.liveProductCount,
      hasLiveTip: snap.hasLiveTip,
      nextKind: SaleKind.product,
      nextIsLive: live,
      wasAlreadyLive: existing.live,
    )) {
      return MonetizeGateResult.paywall();
    }
    final next = existing.copyWith(
      name: name.trim(),
      priceCents: priceCents,
      unlockUrl: unlockUrl?.trim().isEmpty == true ? null : unlockUrl?.trim(),
      clearUnlockUrl: unlockUrl == null || unlockUrl.trim().isEmpty,
      fileLabel: fileLabel?.trim().isEmpty == true ? null : fileLabel?.trim(),
      clearFileLabel: fileLabel == null || fileLabel.trim().isEmpty,
      live: live,
      updatedAt: DateTime.now().toUtc(),
    );
    final saved = await upsertProduct(next);
    return MonetizeGateResult.ok(saved);
  }

  /// Get-or-create the single Free tip (or additional Pro tip).
  Future<MonetizeGateResult<TipLink>> saveTip({
    TipLink? existing,
    String label = 'Tip',
    List<int> suggestedAmountsCents = const [300, 500, 1000],
    required bool live,
    required bool isPro,
  }) async {
    final snap = await snapshot();
    if (MonetizeValidation.requiresConnect(snap.connectStatus)) {
      return MonetizeGateResult.connect();
    }
    if (existing == null &&
        MonetizeValidation.wouldExceedXorOfferCreate(
          isPro: isPro,
          productCount: snap.products.length,
          tipCount: snap.tips.length,
          creating: SaleKind.tip,
          isNew: true,
        )) {
      return MonetizeGateResult.paywall();
    }
    if (MonetizeValidation.wouldExceedLiveOfferLimit(
      isPro: isPro,
      liveProductCount: snap.liveProductCount,
      hasLiveTip: snap.hasLiveTip,
      nextKind: SaleKind.tip,
      nextIsLive: live,
      wasAlreadyLive: existing?.live ?? false,
    )) {
      return MonetizeGateResult.paywall();
    }
    final now = DateTime.now().toUtc();
    final tip = (existing ??
            TipLink(
              id: _uuid.v4(),
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      label: label.trim().isEmpty ? 'Tip' : label.trim(),
      suggestedAmountsCents: suggestedAmountsCents,
      live: live,
      updatedAt: now,
    );
    final saved = await upsertTip(tip);
    return MonetizeGateResult.ok(saved);
  }

  Future<Sale> simulateSale({
    required SaleKind kind,
    required int amountCents,
    String? offerId,
    String? label,
    SaleStatus status = SaleStatus.paid,
    String? sessionId,
    bool isPro = false,
  }) async {
    final now = DateTime.now().toUtc();
    final bps = QuotaPolicy.platformFeeBps(isPro: isPro);
    final fee = QuotaPolicy.applicationFeeCents(amountCents, isPro: isPro);
    return addSale(
      Sale(
        id: _uuid.v4(),
        amountCents: amountCents,
        createdAt: now,
        status: status,
        kind: kind,
        offerId: offerId,
        label: label,
        sessionId: sessionId,
        applicationFeeCents: fee,
        feeBps: bps,
      ),
    );
  }
}
