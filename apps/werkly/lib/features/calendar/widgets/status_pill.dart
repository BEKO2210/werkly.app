import 'package:flutter/material.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      PostStatus.planned => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PostStatus.reminded =>
        (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      PostStatus.done => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      PostStatus.skipped => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
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
