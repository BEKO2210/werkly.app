import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/auth/session_providers.dart';
import 'package:werkly/core/config/app_flags.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/theme/app_spacing.dart';
import 'package:werkly/ui/theme/brand_colors.dart';

/// Screen-ID: S-63 — Account (session, plan pill, logout).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const screenId = ScreenIds.account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isPro = ref.watch(isProProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Konto')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  session.displayLabel.isNotEmpty
                      ? session.displayLabel[0].toUpperCase()
                      : '?',
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.displayLabel, style: text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      session.emailOrGuestLabel,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PlanPill(isPro: isPro),
                  ],
                ),
              ),
            ],
          ),
          if (session.isMock) ...[
            const SizedBox(height: AppSpacing.lg),
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Text(
                  AppFlags.mockAuth
                      ? 'Gast / Mock-Session — Supabase nicht konfiguriert '
                          '(SUPABASE_URL + anon via dart-define).'
                      : 'Mock-Session aktiv.',
                  style: text.bodySmall,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (!session.isAuthenticated)
            FilledButton(
              onPressed: () => context.go(RoutePaths.auth),
              child: const Text('Anmelden'),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Hub öffnen'),
              onTap: () => context.go(RoutePaths.hub),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Media Kit'),
              onTap: () => context.push(RoutePaths.hubMediaKit),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Verkäufe'),
              subtitle: const Text('Stripe Creator-Sales · nicht App-Abo'),
              onTap: () => context.push(RoutePaths.monetizeSales),
            ),
            const Divider(height: AppSpacing.xl),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(
                'Abmelden',
                style: TextStyle(color: scheme.error),
              ),
              onTap: () async {
                final keys = ref.read(llmKeyStoreProvider);
                await ref
                    .read(authSessionProvider.notifier)
                    .signOut(clearLlmKey: true, keys: keys);
                if (context.mounted) {
                  context.go(RoutePaths.auth);
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'S-63 · Session: ${session.mode.name}',
            style: text.bodySmall?.copyWith(color: scheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = isPro ? 'Pro' : 'Free';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPro ? BrandColors.proBadge : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isPro ? BrandColors.onProBadge : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
