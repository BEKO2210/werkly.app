/// Soft quota policy — Free calendar + caption limits; content stays readable.
abstract final class QuotaPolicy {
  static const freeWeeklyCalendarPosts = 10;
  static const freeMonthlyCaptions = 10;
  /// Pro soft anti-abuse cap (UX still shows „unbegrenzt“).
  static const proMonthlyCaptionsSoftCap = 500;

  static const paywallTriggerCalendar = 'limit_calendar_posts';
  static const paywallTriggerTemplates = 'feature_templates';
  static const paywallTriggerCaptions = 'limit_captions';

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
