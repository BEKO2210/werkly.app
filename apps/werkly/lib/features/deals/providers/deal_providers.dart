import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/features/deals/data/deal_file_store.dart';
import 'package:werkly/features/deals/data/deal_memory_store.dart';
import 'package:werkly/features/deals/data/deals_export_client.dart';
import 'package:werkly/features/deals/data/local_deal_repository.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/domain/deal_repository.dart';
import 'package:werkly/features/deals/domain/deals_export_api.dart';

final dealMemoryStoreProvider = Provider<DealMemoryStore>((ref) {
  final store = DealMemoryStore();
  DealFileStore.attachPersist(store);
  return store;
});

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return LocalDealRepository(store: ref.watch(dealMemoryStoreProvider));
});

final dealsExportClientProvider = Provider<DealsExportClient>((ref) {
  return DealsExportClient(store: ref.watch(dealMemoryStoreProvider));
});

LocalDealRepository _local(Ref ref) =>
    ref.read(dealRepositoryProvider) as LocalDealRepository;

/// List + open count for S-40 (active deals only; soft-deleted excluded).
class DealListState {
  const DealListState({
    required this.deals,
    required this.openCount,
  });

  final List<Deal> deals;
  final int openCount;
}

class DealListNotifier extends StateNotifier<AsyncValue<DealListState>> {
  DealListNotifier(this._ref) : super(const AsyncLoading()) {
    refresh();
  }

  final Ref _ref;

  LocalDealRepository get _repo => _local(_ref);

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final deals = await _repo.listDeals();
      final open = deals.where((d) => d.isOpen).length;
      state = AsyncData(DealListState(deals: deals, openCount: open));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<DealGateResult> create({
    required String brand,
    required String title,
    int? amountCents,
    DealStatus status = DealStatus.inquiry,
    DateTime? dueAt,
    String? notes,
  }) async {
    final isPro = _ref.read(isProProvider);
    final result = await _repo.createDeal(
      brand: brand,
      title: title,
      amountCents: amountCents,
      status: status,
      dueAt: dueAt,
      notes: notes,
      isPro: isPro,
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<DealGateResult> update({
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
  }) async {
    final isPro = _ref.read(isProProvider);
    final result = await _repo.updateDeal(
      existing: existing,
      brand: brand,
      title: title,
      amountCents: amountCents,
      clearAmount: clearAmount,
      status: status,
      dueAt: dueAt,
      clearDueAt: clearDueAt,
      notes: notes,
      clearNotes: clearNotes,
      isPro: isPro,
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<Deal?> getById(String id) => _repo.getById(id);

  /// Pro CSV via Edge GET deals-export or local fallback.
  Future<DealsExportResponse> exportCsv() async {
    final isPro = _ref.read(isProProvider);
    return _ref.read(dealsExportClientProvider).export(isPro: isPro);
  }
}

final dealListNotifierProvider =
    StateNotifierProvider<DealListNotifier, AsyncValue<DealListState>>((ref) {
  return DealListNotifier(ref);
});
