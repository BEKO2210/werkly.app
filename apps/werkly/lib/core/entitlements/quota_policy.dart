/// Soft quota policy — Free: 10 posts per **ISO week (Europe/Berlin)**;
/// content stays readable when over quota.
abstract final class QuotaPolicy {
  static const freeWeeklyCalendarPosts = 10;
  static const paywallTriggerCalendar = 'limit_calendar_posts';
  static const paywallTriggerTemplates = 'feature_templates';

  /// Returns true when creating another post should soft-gate to paywall.
  static bool shouldBlockCalendarCreate({
    required bool isPro,
    required int currentWeekCount,
  }) {
    if (isPro) return false;
    return currentWeekCount >= freeWeeklyCalendarPosts;
  }

  static bool canUseWeekTemplates({required bool isPro}) => isPro;
}

/// Pure helper for unit tests (ISO-week count already computed by caller).
bool shouldSoftGateCalendarCreate(int currentWeekCount, {bool isPro = false}) {
  return QuotaPolicy.shouldBlockCalendarCreate(
    isPro: isPro,
    currentWeekCount: currentWeekCount,
  );
}
