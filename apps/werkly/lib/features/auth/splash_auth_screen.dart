import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';

/// Screen-ID: S-00 — SplashAuthScreen · `/auth` · splashAuth
class SplashAuthScreen extends StatelessWidget {
  const SplashAuthScreen({super.key});

  static const screenId = 'S-00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splash / Auth (S-00)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'S-00 · Splash / Auth',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(RoutePaths.planen),
              child: const Text('Weiter (Auth stub → Planen)'),
            ),
          ],
        ),
      ),
    );
  }
}
