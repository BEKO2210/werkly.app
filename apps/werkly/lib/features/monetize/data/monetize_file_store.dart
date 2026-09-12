import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';

/// Optional JSON file persist for [MonetizeMemoryStore] via path_provider.
abstract final class MonetizeFileStore {
  static const fileName = 'werkly_monetize.json';

  static Future<void> attachPersist(MonetizeMemoryStore store) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      store.onLoad = () async {
        if (!await file.exists()) return null;
        return file.readAsString();
      };
      store.onPersist = (json) async {
        await file.writeAsString(json, flush: true);
      };
      await store.loadIfNeeded();
    } catch (_) {
      // Degraded (tests / missing plugin): memory-only.
    }
  }
}
