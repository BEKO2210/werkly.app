import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';

/// Pure helpers for open-deal counting + soft gate (US-F4 Free max 5 open).
abstract final class DealValidation {
  static int countOpen(Iterable<Deal> deals) =>
      deals.where((d) => d.isOpen).length;

  /// Soft-gate when Free would exceed [QuotaPolicy.freeOpenDeals] open deals.
  /// Creating a new open deal, or changing a closed deal → open.
  static bool wouldExceedOpenLimit({
    required bool isPro,
    required int currentOpenCount,
    required bool nextStatusIsOpen,
    required bool wasAlreadyOpen,
  }) {
    if (isPro) return false;
    if (!nextStatusIsOpen) return false;
    // Already open → status change among open does not increase count.
    if (wasAlreadyOpen) return false;
    return currentOpenCount >= QuotaPolicy.freeOpenDeals;
  }

  static bool brandAndTitleOk(String brand, String title) =>
      brand.trim().isNotEmpty && title.trim().isNotEmpty;
}
