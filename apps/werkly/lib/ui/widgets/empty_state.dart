import 'package:flutter/material.dart';
import 'package:werkly/ui/theme/app_spacing.dart';

/// Happy-path empty state: icon + one sentence + single Primary CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String ctaLabel;
  final VoidCallback onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onCta,
              child: Text(ctaLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
