import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/app.dart';
import 'package:werkly/core/config/flavor.dart';

void main() {
  testWidgets('WerklyApp builds', (tester) async {
    FlavorConfig.current = Flavor.dev;
    await tester.pumpWidget(
      const ProviderScope(child: WerklyApp()),
    );
    await tester.pump();
    expect(find.byType(WerklyApp), findsOneWidget);
  });
}
