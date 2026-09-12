import 'package:intl/intl.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';

/// CSV export for Pro (S-42). Columns fixed for tests / Steuerberater handoff.
abstract final class DealCsv {
  static const columns = [
    'id',
    'brand',
    'title',
    'amount_eur',
    'status',
    'status_de',
    'due_at',
    'notes',
    'updated_at',
  ];

  static const taxDisclaimer =
      'Rechnung selbst erstellen · Steuerberater hinzuziehen. '
      'Werkly erstellt keine Rechnungen und gibt keine Steuerberatung.';

  static String escape(String? value) {
    final v = value ?? '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String amountEur(int? amountCents) {
    if (amountCents == null) return '';
    return (amountCents / 100).toStringAsFixed(2);
  }

  static String formatDue(DateTime? dueAt) {
    if (dueAt == null) return '';
    return DateFormat('yyyy-MM-dd').format(dueAt.toLocal());
  }

  /// Full CSV string (header + rows), UTF-8 text.
  static String generate(List<Deal> deals) {
    final buf = StringBuffer();
    buf.writeln(columns.join(','));
    for (final d in deals) {
      buf.writeln(
        [
          escape(d.id),
          escape(d.brand),
          escape(d.title),
          amountEur(d.amountCents),
          d.status.storageValue,
          escape(d.status.labelDe),
          formatDue(d.dueAt),
          escape(d.notes),
          d.updatedAt.toUtc().toIso8601String(),
        ].join(','),
      );
    }
    return buf.toString();
  }
}
