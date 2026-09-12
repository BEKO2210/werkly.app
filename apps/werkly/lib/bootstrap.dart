import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/app.dart';
import 'package:werkly/core/config/flavor.dart';
import 'package:werkly/core/network/supabase_client.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = flavor;

  // Stubs only — no API keys / RC keys / Sentry DSN in scaffold.
  await WerklySupabase.initStub();

  runApp(
    const ProviderScope(
      child: WerklyApp(),
    ),
  );
}
