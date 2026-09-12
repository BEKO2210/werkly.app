import 'package:uuid/uuid.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/data/deal_memory_store.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/domain/deal_repository.dart';
import 'package:werkly/features/deals/domain/deal_validation.dart';

/// Soft-gate result for create / reopen that would exceed Free open limit.
class DealGateResult {
  const DealGateResult._({this.deal, this.softGated = false, this.trigger});

  final Deal? deal;
  final bool softGated;
  final String? trigger;

  bool get ok => deal != null && !softGated;

  factory DealGateResult.ok(Deal deal) => DealGateResult._(deal: deal);

  factory DealGateResult.paywall() => DealGateResult._(
        softGated: true,
        trigger: QuotaPolicy.paywallTriggerDeals,
      );
}

class LocalDealRepository implements DealRepository {
  LocalDealRepository({
    required DealMemoryStore store,
    Uuid? uuid,
  })  : _store = store,
        _uuid = uuid ?? const Uuid();

  final DealMemoryStore _store;
  final Uuid _uuid;

  DealMemoryStore get store => _store;

  @override
  Future<List<Deal>> listDeals() => _store.all();

  @override
  Future<Deal?> getById(String id) => _store.byId(id);

  @override
  Future<Deal> upsert(Deal deal) async {
    final updated = deal.copyWith(updatedAt: DateTime.now().toUtc());
    return _store.upsert(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _store.softDelete(id);
  }

  @override
  Future<int> countOpen() => _store.countOpen();

  /// Create new deal; Free soft-gates when open count ≥ 5 and status is open.
  Future<DealGateResult> createDeal({
    required String brand,
    required String title,
    int? amountCents,
    DealStatus status = DealStatus.inquiry,
    DateTime? dueAt,
    String? notes,
    String? hubId,
    String? mediaKitId,
    required bool isPro,
  }) async {
    final open = await countOpen();
    if (DealValidation.wouldExceedOpenLimit(
      isPro: isPro,
      currentOpenCount: open,
      nextStatusIsOpen: status.isOpen,
      wasAlreadyOpen: false,
    )) {
      return DealGateResult.paywall();
    }
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final deal = Deal(
      id: id,
      clientId: id,
      brand: brand.trim(),
      title: title.trim(),
      amountCents: amountCents,
      currency: 'EUR',
      status: status,
      dueAt: dueAt,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      hubId: hubId,
      mediaKitId: mediaKitId,
      updatedAt: now,
    );
    final saved = await upsert(deal);
    return DealGateResult.ok(saved);
  }

  /// Update existing deal; soft-gate when reopening would exceed Free limit.
  Future<DealGateResult> updateDeal({
    required Deal existing,
    required String brand,
    required String title,
    int? amountCents,
    bool clearAmount = false,
    required DealStatus status,
    DateTime? dueAt,
    bool clearDueAt = false,
    String? notes,
    bool clearNotes = false,
    required bool isPro,
  }) async {
    final open = await countOpen();
    if (DealValidation.wouldExceedOpenLimit(
      isPro: isPro,
      currentOpenCount: open,
      nextStatusIsOpen: status.isOpen,
      wasAlreadyOpen: existing.isOpen,
    )) {
      return DealGateResult.paywall();
    }
    final next = existing.copyWith(
      brand: brand.trim(),
      title: title.trim(),
      amountCents: amountCents,
      clearAmount: clearAmount,
      status: status,
      dueAt: dueAt,
      clearDueAt: clearDueAt,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      clearNotes: clearNotes || (notes?.trim().isEmpty ?? false),
      updatedAt: DateTime.now().toUtc(),
    );
    final saved = await upsert(next);
    return DealGateResult.ok(saved);
  }
}
