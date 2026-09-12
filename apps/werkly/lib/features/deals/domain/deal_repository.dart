import 'package:werkly/features/deals/domain/deal_models.dart';

abstract class DealRepository {
  Future<List<Deal>> listDeals();
  Future<Deal?> getById(String id);
  Future<Deal> upsert(Deal deal);

  /// Soft-delete (sets deleted_at); does not hard-remove.
  Future<void> delete(String id);
  Future<int> countOpen();
}
