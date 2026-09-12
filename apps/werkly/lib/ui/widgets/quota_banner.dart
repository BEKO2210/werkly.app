import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/router/route_paths.dart';

/// Shows a soft upsell when the user is not Pro.
class QuotaBanner extends ConsumerWidget {
  const QuotaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(isProProvider);
    if (pro) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => context.push(RoutePaths.paywall),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.bolt, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Free-Kontingent · Pro ab 9,99 €/Mo',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
