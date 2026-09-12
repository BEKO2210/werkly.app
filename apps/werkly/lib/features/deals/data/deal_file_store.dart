import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:werkly/features/deals/data/deal_memory_store.dart';

/// Optional JSON file persist for [DealMemoryStore] via path_provider.
abstract final class DealFileStore {
  static const fileName = 'werkly_deals.json';

  static Future<void> attachPersist(DealMemoryStore store) async {
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
