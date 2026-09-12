import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/data/deal_memory_store.dart';
import 'package:werkly/features/deals/data/deals_export_client.dart';
import 'package:werkly/features/deals/data/local_deal_repository.dart';
import 'package:werkly/features/deals/domain/deal_csv.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/domain/deal_validation.dart';
import 'package:werkly/features/deals/domain/deals_export_api.dart';

void main() {
  group('open-deal counting (Backend: ≠ invoiced|lost)', () {
    test('open = inquiry|negotiation|won; closed = invoiced|lost', () {
      expect(DealStatus.inquiry.isOpen, isTrue);
      expect(DealStatus.negotiation.isOpen, isTrue);
      expect(DealStatus.won.isOpen, isTrue);
      expect(DealStatus.invoiced.isOpen, isFalse);
      expect(DealStatus.lost.isOpen, isFalse);
      expect(DealStatus.inquiry.storageValue, 'inquiry');
      expect(DealStatus.invoiced.storageValue, 'invoiced');
    });

    test('countOpen ignores Abgerechnet/Verloren and soft-deleted', () {
      final now = DateTime.utc(2026, 9, 12);
      final deals = [
        Deal(
          id: '1',
          clientId: '1',
          brand: 'A',
          title: 't',
          status: DealStatus.inquiry,
          updatedAt: now,
        ),
        Deal(
          id: '2',
          clientId: '2',
          brand: 'B',
          title: 't',
          status: DealStatus.won,
          updatedAt: now,
        ),
        Deal(
          id: '3',
          clientId: '3',
          brand: 'C',
          title: 't',
          status: DealStatus.invoiced,
          updatedAt: now,
        ),
        Deal(
          id: '4',
          clientId: '4',
          brand: 'D',
          title: 't',
          status: DealStatus.lost,
          updatedAt: now,
        ),
        Deal(
          id: '5',
          clientId: '5',
          brand: 'E',
          title: 't',
          status: DealStatus.negotiation,
          updatedAt: now,
          deletedAt: now,
        ),
      ];
      expect(DealValidation.countOpen(deals), 2);
    });

    test('DE labels map pipeline', () {
      expect(DealStatus.inquiry.labelDe, 'Anfrage');
      expect(DealStatus.negotiation.labelDe, 'Verhandlung');
      expect(DealStatus.won.labelDe, 'Gewonnen');
      expect(DealStatus.invoiced.labelDe, 'Abgerechnet');
      expect(DealStatus.lost.labelDe, 'Verloren');
    });
  });

  group('soft gate limit_deals', () {
    test('Free blocks at 5 open; Pro never', () {
      expect(QuotaPolicy.freeOpenDeals, 5);
      expect(QuotaPolicy.paywallTriggerDeals, 'limit_deals');
      expect(shouldSoftGateDealCreate(5), isTrue);
      expect(shouldSoftGateDealCreate(4), isFalse);
      expect(shouldSoftGateDealCreate(5, isPro: true), isFalse);
      expect(shouldSoftGateDealCreate(0), isFalse);
    });

    test('wouldExceed: reopen closed counts; open→open does not', () {
      expect(
        DealValidation.wouldExceedOpenLimit(
          isPro: false,
          currentOpenCount: 5,
          nextStatusIsOpen: true,
          wasAlreadyOpen: false,
        ),
        isTrue,
      );
      expect(
        DealValidation.wouldExceedOpenLimit(
          isPro: false,
          currentOpenCount: 5,
          nextStatusIsOpen: true,
          wasAlreadyOpen: true,
        ),
        isFalse,
      );
      expect(
        DealValidation.wouldExceedOpenLimit(
          isPro: false,
          currentOpenCount: 5,
          nextStatusIsOpen: false,
          wasAlreadyOpen: false,
        ),
        isFalse,
      );
    });

    test('LocalDealRepository Free blocks 6th open create', () async {
      final store = DealMemoryStore();
      final repo = LocalDealRepository(store: store);

      for (var i = 0; i < 5; i++) {
        final r = await repo.createDeal(
          brand: 'Brand$i',
          title: 'Title$i',
          isPro: false,
        );
        expect(r.ok, isTrue, reason: 'create $i should succeed');
      }
      expect(await repo.countOpen(), 5);

      final gated = await repo.createDeal(
        brand: 'Brand6',
        title: 'Title6',
        isPro: false,
      );
      expect(gated.softGated, isTrue);
      expect(gated.trigger, 'limit_deals');
      expect(await repo.countOpen(), 5);

      final closedOk = await repo.createDeal(
        brand: 'Closed',
        title: 'Lost deal',
        status: DealStatus.lost,
        isPro: false,
      );
      expect(closedOk.ok, isTrue);
      expect(await repo.countOpen(), 5);

      final proOk = await repo.createDeal(
        brand: 'ProBrand',
        title: 'ProTitle',
        isPro: true,
      );
      expect(proOk.ok, isTrue);
      expect(await repo.countOpen(), 6);
    });

    test('closing a deal frees a Free slot', () async {
      final store = DealMemoryStore();
      final repo = LocalDealRepository(store: store);
      Deal? first;
      for (var i = 0; i < 5; i++) {
        final r = await repo.createDeal(
          brand: 'B$i',
          title: 'T$i',
          isPro: false,
        );
        first ??= r.deal;
      }
      final closed = await repo.updateDeal(
        existing: first!,
        brand: first.brand,
        title: first.title,
        status: DealStatus.invoiced,
        isPro: false,
      );
      expect(closed.ok, isTrue);
      expect(await repo.countOpen(), 4);

      final again = await repo.createDeal(
        brand: 'New',
        title: 'Slot',
        isPro: false,
      );
      expect(again.ok, isTrue);
      expect(await repo.countOpen(), 5);
    });

    test('soft-delete frees open slot and hides from list', () async {
      final store = DealMemoryStore();
      final repo = LocalDealRepository(store: store);
      final created = await repo.createDeal(
        brand: 'Gone',
        title: 'Soft',
        amountCents: 1000,
        isPro: false,
      );
      expect(created.ok, isTrue);
      expect(await repo.countOpen(), 1);

      await repo.delete(created.deal!.id);
      expect(await repo.countOpen(), 0);
      expect(await repo.listDeals(), isEmpty);
      expect(await repo.getById(created.deal!.id), isNull);

      final tombstones = await store.all(includeDeleted: true);
      expect(tombstones, hasLength(1));
      expect(tombstones.single.isDeleted, isTrue);
      expect(tombstones.single.deletedAt, isNotNull);
      expect(tombstones.single.toJson()['amount_cents'], 1000);
      expect(tombstones.single.toJson()['currency'], 'EUR');
      expect(tombstones.single.toJson()['deleted_at'], isNotNull);
    });
  });

  group('CSV columns + deals-export client', () {
    test('header matches contract + amount EUR', () {
      expect(
        DealCsv.columns,
        [
          'id',
          'brand',
          'title',
          'amount_eur',
          'status',
          'status_de',
          'due_at',
          'notes',
          'updated_at',
        ],
      );
      expect(DealCsv.amountEur(1999), '19.99');
      expect(DealCsv.amountEur(null), '');
      expect(DealCsv.taxDisclaimer, contains('Steuerberater'));
      expect(DealCsv.taxDisclaimer, contains('Rechnung'));
    });

    test('generate includes header and rows', () {
      final deal = Deal(
        id: 'abc',
        clientId: 'abc',
        brand: 'Nike, Inc',
        title: 'Reel "Summer"',
        amountCents: 150000,
        status: DealStatus.negotiation,
        dueAt: DateTime.utc(2026, 10, 1),
        notes: 'Line\nbreak',
        updatedAt: DateTime.utc(2026, 9, 12, 12),
      );
      final csv = DealCsv.generate([deal]);
      final lines = csv.trimRight().split('\n');
      expect(lines.first, DealCsv.columns.join(','));
      expect(lines, hasLength(2));
      expect(lines[1], contains('"Nike, Inc"'));
      expect(lines[1], contains('1500.00'));
      expect(lines[1], contains('negotiation'));
      expect(lines[1], contains('Verhandlung'));
      expect(shouldSoftGateDealExport(isPro: false), isTrue);
      expect(shouldSoftGateDealExport(isPro: true), isFalse);
      expect(QuotaPolicy.paywallTriggerDealExport, 'feature_deal_export');
    });

    test('DealsExportClient local fallback for Pro; 402 for Free', () async {
      final store = DealMemoryStore();
      final repo = LocalDealRepository(store: store);
      await repo.createDeal(
        brand: 'Acme',
        title: 'Collab',
        amountCents: 50000,
        isPro: true,
      );
      final client = DealsExportClient(store: store);

      await expectLater(
        client.export(isPro: false),
        throwsA(
          isA<DealsExportApiError>().having(
            (e) => e.httpStatus,
            '402',
            402,
          ),
        ),
      );

      final res = await client.export(isPro: true);
      expect(res.source, 'local');
      expect(res.rowCount, 1);
      expect(res.csv, startsWith(DealCsv.columns.join(',')));
      expect(res.csv, contains('Acme'));
      expect(res.csv, contains('500.00'));
    });

    test('DealsExportResponse mock JSON shape', () {
      const sample = {
        'csv':
            'id,brand,title,amount_eur,status,status_de,due_at,notes,updated_at\n',
        'content_type': 'text/csv',
        'row_count': 0,
        'source': 'edge',
      };
      final dto = DealsExportResponse.fromJson(sample);
      expect(dto.contentType, 'text/csv');
      expect(dto.source, 'edge');
      expect(dto.toJson()['content_type'], 'text/csv');
    });
  });
}
