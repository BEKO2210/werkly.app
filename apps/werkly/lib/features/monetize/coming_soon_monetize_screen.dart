import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-70 — Fallback only. Redirects to real MonetizeHome (S-50).
class ComingSoonMonetizeScreen extends StatefulWidget {
  const ComingSoonMonetizeScreen({super.key});

  static const screenId = ScreenIds.monetizeComingSoon;

  @override
  State<ComingSoonMonetizeScreen> createState() =>
      _ComingSoonMonetizeScreenState();
}

class _ComingSoonMonetizeScreenState extends State<ComingSoonMonetizeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(RoutePaths.monetize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verkaufen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(RoutePaths.monetize),
              child: const Text('Weiter zu Monetize (S-50)'),
            ),
          ],
        ),
      ),
    );
  }
}
