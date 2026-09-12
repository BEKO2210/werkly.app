import 'package:flutter/material.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';

class ConnectStatusCard extends StatelessWidget {
  const ConnectStatusCard({
    super.key,
    required this.status,
    this.onTap,
  });

  final ConnectStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (status) {
      ConnectStatus.none => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.link_off,
        ),
      ConnectStatus.pending => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.hourglass_top,
        ),
      ConnectStatus.active => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.verified_outlined,
        ),
      ConnectStatus.restricted => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.gpp_maybe_outlined,
        ),
    };
    return Card(
      color: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe Connect · ${status.labelDe}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.hintDe,
                      style: TextStyle(fontSize: 12, color: fg),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
