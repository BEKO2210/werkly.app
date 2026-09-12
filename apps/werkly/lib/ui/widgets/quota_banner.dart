import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/router/route_paths.dart';

/// Soft upsell banner. When [used]/[limit] are set, shows weekly calendar quota.
class QuotaBanner extends ConsumerWidget {
  const QuotaBanner({
    super.key,
    this.used,
    this.limit,
    this.label,
    this.trigger,
  });

  final int? used;
  final int? limit;
  final String? label;
  final String? trigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(isProProvider);
    if (pro) return const SizedBox.shrink();

    final u = used;
    final l = limit ?? QuotaPolicy.freeWeeklyCalendarPosts;
    final text = (u != null)
        ? '${label ?? "Posts"} · $u/$l Free'
        : 'Free-Kontingent · Pro ab 9,99 €/Mo';

    final over = u != null && u >= l;

    return Material(
      color: over
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () {
          final t = trigger ?? QuotaPolicy.paywallTriggerCalendar;
          context.push('${RoutePaths.paywall}?trigger=$t');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(over ? Icons.lock_outline : Icons.bolt, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13)),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
