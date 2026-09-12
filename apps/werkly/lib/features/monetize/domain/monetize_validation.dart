import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';

/// Pure helpers: Free tip-OR-1-product, connect required for live, 2nd product gate.
abstract final class MonetizeValidation {
  static int countLiveProducts(Iterable<Product> products) =>
      products.where((p) => p.live).length;

  static bool hasLiveTip(Iterable<TipLink> tips) => tips.any((t) => t.live);

  static int liveOfferSlots({
    required Iterable<Product> products,
    required Iterable<TipLink> tips,
  }) =>
      countLiveProducts(products) + (hasLiveTip(tips) ? 1 : 0);

  /// Soft-gate when Free would create a 2nd product (draft or live).
  static bool wouldExceedProductCreateLimit({
    required bool isPro,
    required int currentProductCount,
  }) {
    if (isPro) {
      return currentProductCount >= QuotaPolicy.proLiveProducts;
    }
    return currentProductCount >= QuotaPolicy.freeLiveProducts;
  }

  /// Free: tip **or** 1 product live. Pro: tip + up to 10 products.
  static bool wouldExceedLiveOfferLimit({
    required bool isPro,
    required int liveProductCount,
    required bool hasLiveTip,
    required SaleKind nextKind,
    required bool nextIsLive,
    required bool wasAlreadyLive,
  }) {
    if (!nextIsLive) return false;
    if (wasAlreadyLive) return false;
    if (isPro) {
      if (nextKind == SaleKind.tip) return false;
      return liveProductCount >= QuotaPolicy.proLiveProducts;
    }
    final used = liveProductCount + (hasLiveTip ? 1 : 0);
    return used >= QuotaPolicy.freeLiveOffers;
  }

  /// Free 1 offer slot: tip XOR 1 product (create, not just live).
  static bool wouldExceedXorOfferCreate({
    required bool isPro,
    required int productCount,
    required int tipCount,
    required SaleKind creating,
    required bool isNew,
  }) {
    if (!isNew) return false;
    return QuotaPolicy.shouldBlockStripeOfferCreate(
      isPro: isPro,
      productCount: productCount,
      tipCount: tipCount,
      creatingProduct: creating == SaleKind.product,
    );
  }

  /// Products, tips, and checkout require Connect `active`.
  static bool requiresConnect(ConnectStatus status) => !status.isActive;

  /// Live / create requires Connect `active`.
  static bool canSetLive(ConnectStatus status) => status.canGoLive;

  static bool nameAndPriceOk(String name, int? priceCents) =>
      name.trim().isNotEmpty && priceCents != null && priceCents > 0;

  static bool tipAmountsOk(Iterable<int> amounts) =>
      amounts.isNotEmpty &&
      amounts.every((a) => a >= QuotaPolicy.minTipAmountCents);

  static bool tipCheckoutAmountOk(int? tipAmountCents) =>
      tipAmountCents != null &&
      tipAmountCents >= QuotaPolicy.minTipAmountCents;
}

bool shouldSoftGateSecondProduct({
  required int currentProductCount,
  bool isPro = false,
}) {
  return MonetizeValidation.wouldExceedProductCreateLimit(
    isPro: isPro,
    currentProductCount: currentProductCount,
  );
}

bool shouldSoftGateLiveOffer({
  required int liveProductCount,
  required bool hasLiveTip,
  required SaleKind nextKind,
  bool nextIsLive = true,
  bool wasAlreadyLive = false,
  bool isPro = false,
}) {
  return MonetizeValidation.wouldExceedLiveOfferLimit(
    isPro: isPro,
    liveProductCount: liveProductCount,
    hasLiveTip: hasLiveTip,
    nextKind: nextKind,
    nextIsLive: nextIsLive,
    wasAlreadyLive: wasAlreadyLive,
  );
}
