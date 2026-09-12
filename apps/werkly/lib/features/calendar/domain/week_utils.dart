/// ISO-week helpers for F1 quota + navigation.
///
/// Free quota window = **current ISO week in Europe/Berlin**, not rolling 7d.
abstract final class WeekUtils {
  static const berlinOffset = Duration(hours: 2); // CEST approx; see toBerlin

  /// Monday 00:00 of the ISO week containing [instant], in local calendar
  /// semantics. Callers should pass Berlin-local wall time when possible.
  static DateTime startOfIsoWeek(DateTime instant) {
    final d = DateTime(instant.year, instant.month, instant.day);
    // DateTime.weekday: Mon=1 … Sun=7
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static DateTime endOfIsoWeek(DateTime weekStart) {
    final start = startOfIsoWeek(weekStart);
    return start.add(const Duration(days: 7));
  }

  /// Approximate Europe/Berlin wall clock without `timezone` DB dependency
  /// in unit tests. Production UI should prefer `flutter_timezone` + TZ.
  static DateTime nowBerlin([DateTime? utcNow]) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    // Simplified: use UTC+1 (CET) Nov–Mar, UTC+2 (CEST) Mar–Oct.
    final month = utc.month;
    final isCest = month > 3 && month < 10 ||
        (month == 3 && utc.day >= 25) ||
        (month == 10 && utc.day < 25);
    return utc.add(Duration(hours: isCest ? 2 : 1));
  }

  static DateTime currentWeekStartBerlin([DateTime? utcNow]) {
    return startOfIsoWeek(nowBerlin(utcNow));
  }

  static int isoWeekNumber(DateTime weekStart) {
    final start = startOfIsoWeek(weekStart);
    // ISO week: week of Thursday
    final thursday = start.add(const Duration(days: 3));
    final jan4 = DateTime(thursday.year, 1, 4);
    final week1Monday = startOfIsoWeek(jan4);
    return thursday.difference(week1Monday).inDays ~/ 7 + 1;
  }

  static bool isInIsoWeek(DateTime instant, DateTime weekStart) {
    final start = startOfIsoWeek(weekStart);
    final end = endOfIsoWeek(start);
    return !instant.isBefore(start) && instant.isBefore(end);
  }
}
