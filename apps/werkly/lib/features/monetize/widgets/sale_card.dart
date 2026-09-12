import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';

class SaleCard extends StatelessWidget {
  const SaleCard({super.key, required this.sale});

  final Sale sale;

  static final _eur = NumberFormat.currency(
    locale: 'de_DE',
    symbol: '€',
    decimalDigits: 2,
  );

  static final _date = DateFormat('dd.MM.yyyy HH:mm', 'de_DE');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.label?.isNotEmpty == true
                        ? sale.label!
                        : sale.kind.labelDe,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _StatusPill(status: sale.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _eur.format(sale.amountCents / 100),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${sale.kind.labelDe} · ${_date.format(sale.createdAt.toLocal())}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            if (sale.applicationFeeCents > 0)
              Text(
                'Platform-Fee ${_eur.format(sale.applicationFeeCents / 100)}'
                '${sale.feeBps != null ? ' (${sale.feeBps! / 100} %)' : ''}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SaleStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      SaleStatus.paid => (scheme.primaryContainer, scheme.onPrimaryContainer),
      SaleStatus.pending => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      SaleStatus.refunded => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      SaleStatus.failed => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelDe,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
