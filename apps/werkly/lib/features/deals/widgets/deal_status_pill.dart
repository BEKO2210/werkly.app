import 'package:flutter/material.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';

class DealStatusPill extends StatelessWidget {
  const DealStatusPill({super.key, required this.status});

  final DealStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      DealStatus.inquiry => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      DealStatus.negotiation => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      DealStatus.won => (scheme.primaryContainer, scheme.onPrimaryContainer),
      DealStatus.invoiced => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      DealStatus.lost => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
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
