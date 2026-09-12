/// Soft quota policy — Free calendar + caption + hub + deals limits; content stays readable.
abstract final class QuotaPolicy {
  static const freeWeeklyCalendarPosts = 10;
  static const freeMonthlyCaptions = 10;
  /// Pro soft anti-abuse cap (UX still shows „unbegrenzt“).
  static const proMonthlyCaptionsSoftCap = 500;

  /// Free: exactly 1 hub.
  static const freeHubLimit = 1;

  /// Free: max 5 open deals (status ≠ Abgerechnet/Verloren).
  static const freeOpenDeals = 5;

  static const paywallTriggerCalendar = 'limit_calendar_posts';
  static const paywallTriggerTemplates = 'feature_templates';
  static const paywallTriggerCaptions = 'limit_captions';
  static const paywallTriggerHubBranding = 'limit_hub_branding';
  static const paywallTriggerDeals = 'limit_deals';
  static const paywallTriggerDealExport = 'feature_deal_export';

  /// Returns true when creating another post should soft-gate to paywall.
  static bool shouldBlockCalendarCreate({
    required bool isPro,
    required int currentWeekCount,
  }) {
    if (isPro) return false;
    return currentWeekCount >= freeWeeklyCalendarPosts;
  }

  static bool canUseWeekTemplates({required bool isPro}) => isPro;

  /// Soft-gate before generate/regenerate when Free used ≥ 10.
  static bool shouldBlockCaptionGenerate({
    required bool isPro,
    required int usedThisMonth,
  }) {
    if (isPro) {
      return usedThisMonth >= proMonthlyCaptionsSoftCap;
    }
    return usedThisMonth >= freeMonthlyCaptions;
  }

  static int captionLimit({required bool isPro}) =>
      isPro ? proMonthlyCaptionsSoftCap : freeMonthlyCaptions;

  /// Soft-gate when Free toggles branding off or edits custom slug.
  static bool shouldBlockHubBrandingOrSlug({
    required bool isPro,
    required bool wantsBrandingOff,
    required bool wantsCustomSlug,
  }) {
    if (isPro) return false;
    return wantsBrandingOff || wantsCustomSlug;
  }

  /// Soft-gate when Free would create/reopen beyond 5 open deals.
  static bool shouldBlockDealCreate({
    required bool isPro,
    required int currentOpenCount,
  }) {
    if (isPro) return false;
    return currentOpenCount >= freeOpenDeals;
  }

  /// CSV export is Pro-only (soft gate).
  static bool shouldBlockDealExport({required bool isPro}) => !isPro;
}

/// Pure helper for unit tests (ISO-week count already computed by caller).
bool shouldSoftGateCalendarCreate(int currentWeekCount, {bool isPro = false}) {
  return QuotaPolicy.shouldBlockCalendarCreate(
    isPro: isPro,
    currentWeekCount: currentWeekCount,
  );
}

bool shouldSoftGateCaptionGenerate(int usedThisMonth, {bool isPro = false}) {
  return QuotaPolicy.shouldBlockCaptionGenerate(
    isPro: isPro,
    usedThisMonth: usedThisMonth,
  );
}

bool shouldSoftGateHubBrandingOrSlug({
  required bool wantsBrandingOff,
  required bool wantsCustomSlug,
  bool isPro = false,
}) {
  return QuotaPolicy.shouldBlockHubBrandingOrSlug(
    isPro: isPro,
    wantsBrandingOff: wantsBrandingOff,
    wantsCustomSlug: wantsCustomSlug,
  );
}

bool shouldSoftGateDealCreate(int currentOpenCount, {bool isPro = false}) {
  return QuotaPolicy.shouldBlockDealCreate(
    isPro: isPro,
    currentOpenCount: currentOpenCount,
  );
}

bool shouldSoftGateDealExport({bool isPro = false}) {
  return QuotaPolicy.shouldBlockDealExport(isPro: isPro);
}
