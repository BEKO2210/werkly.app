import 'package:werkly/features/monetize/domain/monetize_models.dart';

abstract class MonetizeRepository {
  Future<ConnectStatus> connectStatus();
  Future<ConnectStatus> setConnectStatus(ConnectStatus status);
  Future<List<Product>> listProducts();
  Future<Product?> getProduct(String id);
  Future<Product> upsertProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<List<TipLink>> listTips();
  Future<TipLink?> getTip(String id);
  Future<TipLink> upsertTip(TipLink tip);
  Future<void> deleteTip(String id);
  Future<List<Sale>> listSales();
  Future<Sale> addSale(Sale sale);
  Future<MonetizeSnapshot> snapshot();
}
