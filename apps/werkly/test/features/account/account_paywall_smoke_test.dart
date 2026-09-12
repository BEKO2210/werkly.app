import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/auth/auth_service.dart';
import 'package:werkly/core/auth/session_providers.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/features/account/account_screen.dart';
import 'package:werkly/features/paywall/paywall_screen.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/theme/brand_colors.dart';

void main() {
  test('S-63 screen id locked', () {
    expect(AccountScreen.screenId, ScreenIds.account);
    expect(ScreenIds.account, 'S-63');
  });

  test('Brand primary locked #0F766E · Pro Indigo #4338CA', () {
    expect(BrandColors.primary, const Color(0xFF0F766E));
    expect(BrandColors.proBadge, const Color(0xFF4338CA));
  });

  testWidgets('GL-02 Account shows Gast/Mock + Free pill + Logout',
      (tester) async {
    final service = AuthService();
    await service.signInMock(email: 'gast@mock.werkly');

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const AccountScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, __) => const Scaffold(body: Text('auth')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
          isProProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('gast@mock.werkly'), findsWidgets);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Abmelden'), findsOneWidget);
  });

  testWidgets('GL-07 Paywall benefit-first + 9,99 + Weiter mit Free',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/paywall',
      routes: [
        GoRoute(
          path: '/paywall',
          builder: (_, __) => const PaywallScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unbegrenzte Captions & Deals'), findsOneWidget);
    expect(find.textContaining('9,99 €/Mo'), findsWidgets);
    expect(find.text('Weiter mit Free'), findsOneWidget);
  });
}
