import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/secure/llm_key_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GL-03 masked last-4 never returns full key', () async {
    final store = LlmKeyStore();
    await store.save('sk-test-abcdefghijklmnop');
    final masked = await store.maskedLast4();
    expect(masked, isNotNull);
    expect(masked, isNot(contains('sk-test-abcdefghijklmnop')));
    expect(masked!.endsWith('mnop'), isTrue);
    expect(masked.startsWith('••••'), isTrue);
    await store.clear();
    expect(await store.maskedLast4(), isNull);
  });
}
