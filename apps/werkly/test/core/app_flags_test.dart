import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/config/app_flags.dart';
import 'package:werkly/core/network/supabase_client.dart';

void main() {
  tearDown(() {
    WerklySupabase.debugMarkConfigured(false);
  });

  test('GL-06 mock flags true when Supabase not configured', () {
    WerklySupabase.debugMarkConfigured(false);
    expect(AppFlags.mockCaptions, isTrue);
    expect(AppFlags.mockStripe, isTrue);
    expect(AppFlags.useLiveCaptions, isFalse);
    expect(AppFlags.snapshot.containsKey('mockAuth'), isTrue);
  });

  test('GL-04 useLiveCaptions when configured', () {
    WerklySupabase.debugMarkConfigured(true);
    expect(AppFlags.mockCaptions, isFalse);
    expect(AppFlags.useLiveCaptions, isTrue);
  });
}
