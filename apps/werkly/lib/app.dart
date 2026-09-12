import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/config/flavor.dart';
import 'package:werkly/router/app_router.dart';
import 'package:werkly/ui/theme/app_theme.dart';

class WerklyApp extends ConsumerWidget {
  const WerklyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Werkly (${FlavorConfig.label})',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: FlavorConfig.current != Flavor.prod,
    );
  }
}
