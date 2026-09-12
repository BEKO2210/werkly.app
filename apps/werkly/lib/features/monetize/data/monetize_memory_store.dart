import 'dart:convert';

import 'package:werkly/features/monetize/domain/monetize_models.dart';

/// In-memory + optional JSON blob persist for F5 products / tips / sales / connect.
///
/// // TODO(sync): push/pull when auth + Stripe Edge are wired.
class MonetizeMemoryStore {
  final Map<String, Product> _products = {};
  final Map<String, TipLink> _tips = {};
  final Map<String, Sale> _sales = {};
  ConnectStatus _connect = ConnectStatus.none;

  Future<void> Function(String json)? onPersist;
  Future<String?> Function()? onLoad;
  bool _loaded = false;

  Future<void> loadIfNeeded() async {
    if (_loaded) return;
    _loaded = true;
    final loader = onLoad;
    if (loader == null) return;
    final raw = await loader();
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _connect = ConnectStatus.fromStorage(
        map['stripe_connect_status'] as String?,
      );
      for (final e in (map['products'] as List? ?? const [])) {
        final p = Product.fromJson(Map<String, dynamic>.from(e as Map));
        _products[p.id] = p;
      }
      for (final e in (map['tips'] as List? ?? const [])) {
        final t = TipLink.fromJson(Map<String, dynamic>.from(e as Map));
        _tips[t.id] = t;
      }
      for (final e in (map['sales'] as List? ?? const [])) {
        final s = Sale.fromJson(Map<String, dynamic>.from(e as Map));
        _sales[s.id] = s;
      }
    } catch (_) {
      // Corrupt blob — start empty.
    }
  }

  Future<void> _persist() async {
    final cb = onPersist;
    if (cb == null) return;
    await cb(
      jsonEncode({
        'stripe_connect_status': _connect.storageValue,
        'products': _products.values.map((p) => p.toJson()).toList(),
        'tips': _tips.values.map((t) => t.toJson()).toList(),
        'sales': _sales.values.map((s) => s.toJson()).toList(),
      }),
    );
  }

  Future<ConnectStatus> connectStatus() async {
    await loadIfNeeded();
    return _connect;
  }

  Future<ConnectStatus> setConnectStatus(ConnectStatus status) async {
    await loadIfNeeded();
    _connect = status;
    await _persist();
    return _connect;
  }

  Future<List<Product>> products() async {
    await loadIfNeeded();
    final list = _products.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  Future<Product?> productById(String id) async {
    await loadIfNeeded();
    return _products[id];
  }

  Future<Product> upsertProduct(Product product) async {
    await loadIfNeeded();
    _products[product.id] = product;
    await _persist();
    return product;
  }

  Future<void> deleteProduct(String id) async {
    await loadIfNeeded();
    _products.remove(id);
    await _persist();
  }

  Future<List<TipLink>> tips() async {
    await loadIfNeeded();
    final list = _tips.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  Future<TipLink?> tipById(String id) async {
    await loadIfNeeded();
    return _tips[id];
  }

  Future<TipLink> upsertTip(TipLink tip) async {
    await loadIfNeeded();
    _tips[tip.id] = tip;
    await _persist();
    return tip;
  }

  Future<void> deleteTip(String id) async {
    await loadIfNeeded();
    _tips.remove(id);
    await _persist();
  }

  Future<List<Sale>> sales() async {
    await loadIfNeeded();
    final list = _sales.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  Future<Sale> addSale(Sale sale) async {
    await loadIfNeeded();
    _sales[sale.id] = sale;
    await _persist();
    return sale;
  }

  Future<void> clear() async {
    _products.clear();
    _tips.clear();
    _sales.clear();
    _connect = ConnectStatus.none;
    await _persist();
  }

  Future<MonetizeSnapshot> snapshot() async {
    await loadIfNeeded();
    return MonetizeSnapshot(
      connectStatus: _connect,
      products: await products(),
      tips: await tips(),
      sales: await sales(),
    );
  }
}
