import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/widgets/deal_status_pill.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
  });

  final Deal deal;
  final VoidCallback onTap;

  static final _eur = NumberFormat.currency(
    locale: 'de_DE',
    symbol: '€',
    decimalDigits: 2,
  );

  static final _dueFmt = DateFormat('dd.MM.yyyy', 'de_DE');

  @override
  Widget build(BuildContext context) {
    final amount = deal.amountCents != null
        ? _eur.format(deal.amountCents! / 100)
        : '—';
    final due = deal.dueAt != null
        ? _dueFmt.format(deal.dueAt!.toLocal())
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deal.brand,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DealStatusPill(status: deal.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                deal.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (due != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      due,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
