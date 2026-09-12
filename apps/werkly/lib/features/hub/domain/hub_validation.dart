import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';

/// Pure F3 rules: share-ready, one-hub Free, branding soft gate.
abstract final class HubValidation {
  /// Share ready when hub has ≥1 enabled link with non-empty label.
  static bool isShareReady(Hub hub) {
    return hub.links.any(
      (l) => l.isEnabled && l.label.trim().isNotEmpty,
    );
  }

  /// Free plan: at most one hub per user.
  static bool wouldExceedFreeHubLimit({
    required bool isPro,
    required int existingHubCountForUser,
  }) {
    if (isPro) return false;
    return existingHubCountForUser >= QuotaPolicy.freeHubLimit;
  }

  /// Soft-gate when Free tries branding off or custom slug edit.
  static bool shouldSoftGateBrandingOrSlug({
    required bool isPro,
    required bool wantsBrandingOff,
    required bool wantsCustomSlug,
  }) {
    if (isPro) return false;
    return wantsBrandingOff || wantsCustomSlug;
  }
}

bool shouldSoftGateHubBranding({
  required bool isPro,
  required bool wantsBrandingOff,
  required bool wantsCustomSlug,
}) {
  return HubValidation.shouldSoftGateBrandingOrSlug(
    isPro: isPro,
    wantsBrandingOff: wantsBrandingOff,
    wantsCustomSlug: wantsCustomSlug,
  );
}

bool isHubShareReady(Hub hub) => HubValidation.isShareReady(hub);
