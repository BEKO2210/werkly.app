import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/core/network/supabase_client.dart';
import 'package:werkly/features/captions/data/edge_caption_client.dart';
import 'package:werkly/features/hub/data/hub_memory_store.dart';
import 'package:werkly/features/hub/data/local_hub_repository.dart';
import 'package:werkly/features/hub/domain/hub_models.dart';
import 'package:werkly/features/monetize/data/local_monetize_repository.dart';
import 'package:werkly/features/monetize/data/monetize_memory_store.dart';
import 'package:werkly/features/monetize/data/stripe_checkout_client.dart';
import 'package:werkly/features/monetize/data/stripe_connect_client.dart';
import 'package:werkly/features/monetize/domain/monetize_models.dart';
import 'package:werkly/features/monetize/domain/monetize_validation.dart';
import 'package:werkly/features/monetize/domain/stripe_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    WerklySupabase.debugMarkConfigured(false);
  });

  group('ConnectStatus enum (OpenAPI none|pending|active|restricted)', () {
    test('storage values and not_started alias', () {
      expect(ConnectStatus.none.storageValue, 'none');
      expect(ConnectStatus.pending.storageValue, 'pending');
      expect(ConnectStatus.active.storageValue, 'active');
      expect(ConnectStatus.restricted.storageValue, 'restricted');
      expect(ConnectStatus.fromStorage('not_started'), ConnectStatus.none);
      expect(ConnectStatus.fromStorage(null), ConnectStatus.none);
      expect(ConnectStatus.active.canGoLive, isTrue);
      expect(ConnectStatus.none.canCheckout, isFalse);
    });
  });

  group('plan_limits fee-bps + Free XOR offer', () {
    test('Free 10% / Pro 5%', () {
      expect(QuotaPolicy.freePlatformFeeBps, 1000);
      expect(QuotaPolicy.proPlatformFeeBps, 500);
      expect(QuotaPolicy.applicationFeeCents(1000, isPro: false), 100);
      expect(QuotaPolicy.applicationFeeCents(1000, isPro: true), 50);
      expect(QuotaPolicy.paywallTriggerStripeProducts, 'limit_stripe_products');
    });

    test('Free tip XOR 1 product; Pro tip + 10 products', () {
      expect(QuotaPolicy.freeLiveOffers, 1);
      expect(
        shouldSoftGateStripeOfferCreate(
          productCount: 1,
          tipCount: 0,
          creatingProduct: true,
        ),
        isTrue,
      );
      expect(
        shouldSoftGateStripeOfferCreate(
          productCount: 0,
          tipCount: 1,
          creatingProduct: true,
        ),
        isTrue,
      );
      expect(
        shouldSoftGateStripeOfferCreate(
          productCount: 0,
          tipCount: 0,
          creatingProduct: true,
        ),
        isFalse,
      );
      expect(
        shouldSoftGateSecondProduct(currentProductCount: 1),
        isTrue,
      );
      expect(
        shouldSoftGateSecondProduct(currentProductCount: 1, isPro: true),
        isFalse,
      );
      expect(
        shouldSoftGateSecondProduct(currentProductCount: 10, isPro: true),
        isTrue,
      );
    });
  });

  group('connect required before products/tips + live', () {
    test('create product without active Connect → 403 path', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      expect(await repo.connectStatus(), ConnectStatus.none);

      final gated = await repo.createProduct(
        name: 'Guide',
        priceCents: 999,
        isPro: false,
      );
      expect(gated.connectRequired, isTrue);
      expect(gated.error?.isConnectInactive, isTrue);
      expect(await repo.listProducts(), isEmpty);
    });

    test('live requires active; after onboard mock can create', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      await repo.setConnectStatus(ConnectStatus.active);

      final created = await repo.createProduct(
        name: 'Guide',
        priceCents: 1999,
        live: true,
        isPro: false,
      );
      expect(created.ok, isTrue);
      expect(created.value!.live, isTrue);

      final second = await repo.createProduct(
        name: 'Pack 2',
        priceCents: 500,
        isPro: false,
      );
      expect(second.softGated, isTrue);
      expect(second.trigger, 'limit_stripe_products');
    });

    test('Free XOR: tip then product is gated', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      await repo.setConnectStatus(ConnectStatus.active);

      final tip = await repo.saveTip(live: true, isPro: false);
      expect(tip.ok, isTrue);

      final product = await repo.createProduct(
        name: 'Also',
        priceCents: 300,
        isPro: false,
      );
      expect(product.softGated, isTrue);
    });

    test('Pro can have tip + product', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      await repo.setConnectStatus(ConnectStatus.active);
      expect((await repo.saveTip(live: true, isPro: true)).ok, isTrue);
      expect(
        (await repo.createProduct(
          name: 'Pro Pack',
          priceCents: 999,
          live: true,
          isPro: true,
        ))
            .ok,
        isTrue,
      );
    });
  });

  group('StripeConnectClient + CheckoutClient mocks', () {
    test('onboard mock pending then refresh → active', () async {
      final store = MonetizeMemoryStore();
      final client = StripeConnectClient(store: store);
      final res = await client.startOnboard();
      expect(res.url, contains('connect.stripe.com'));
      expect(res.stripeConnectStatus, ConnectStatus.pending);
      expect(await store.connectStatus(), ConnectStatus.pending);

      final refreshed = await client.refreshStatus();
      expect(refreshed, ConnectStatus.active);
    });

    test('checkout without connect = 403 connect_inactive', () async {
      final store = MonetizeMemoryStore();
      final client = StripeCheckoutClient(store: store);
      await expectLater(
        client.checkout(
          request: const CheckoutRequest(
            kind: SaleKind.product,
            id: '00000000-0000-4000-8000-000000000001',
          ),
          isPro: false,
          recordSale: false,
        ),
        throwsA(
          isA<StripeApiError>()
              .having((e) => e.isConnectInactive, '403', isTrue)
              .having((e) => e.code, 'code', 'connect_inactive'),
        ),
      );
    });

    test('tip checkout requires tip_amount_cents ≥ 100', () async {
      final store = MonetizeMemoryStore();
      await store.setConnectStatus(ConnectStatus.active);
      final client = StripeCheckoutClient(store: store);
      await expectLater(
        client.checkout(
          request: const CheckoutRequest(
            kind: SaleKind.tip,
            id: 'tip-1',
          ),
          isPro: false,
          recordSale: false,
        ),
        throwsA(
          isA<StripeApiError>().having((e) => e.httpStatus, '400', 400),
        ),
      );
    });

    test('checkout 200 mock records sale with fee-bps', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      await repo.setConnectStatus(ConnectStatus.active);
      final product = await repo.createProduct(
        name: 'Pack',
        priceCents: 1000,
        live: true,
        isPro: false,
      );
      expect(product.ok, isTrue);

      final client = StripeCheckoutClient(store: store);
      final res = await client.checkout(
        request: CheckoutRequest(
          kind: SaleKind.product,
          id: product.value!.id,
        ),
        isPro: false,
      );
      expect(res.url, StripeMockFixtures.mockCheckoutUrl);
      expect(res.source, 'mock');
      final sales = await store.sales();
      expect(sales, hasLength(1));
      expect(sales.first.amountCents, 1000);
      expect(sales.first.applicationFeeCents, 100);
      expect(sales.first.feeBps, 1000);
    });

    test('fixture JSON shapes match contracts/mocks', () async {
      final pending = await rootBundle
          .loadString('assets/contracts/mocks/stripe-connect-onboard-200.json');
      final active = await rootBundle.loadString(
        'assets/contracts/mocks/stripe-connect-onboard-200-active.json',
      );
      final ok = await rootBundle
          .loadString('assets/contracts/mocks/stripe-checkout-200.json');
      final err403 = await rootBundle.loadString(
        'assets/contracts/mocks/stripe-checkout-403-connect.json',
      );
      final err402 = await rootBundle
          .loadString('assets/contracts/mocks/stripe-checkout-402-quota.json');

      expect(
        ConnectOnboardResponse.fromJson(
          jsonDecode(pending) as Map<String, dynamic>,
        ).stripeConnectStatus,
        ConnectStatus.pending,
      );
      expect(
        ConnectOnboardResponse.fromJson(
          jsonDecode(active) as Map<String, dynamic>,
        ).stripeConnectStatus,
        ConnectStatus.active,
      );
      expect(
        CheckoutResponse.fromJson(jsonDecode(ok) as Map<String, dynamic>).url,
        contains('checkout.stripe.com'),
      );
      final e403 = StripeApiError.fromJson(
        jsonDecode(err403) as Map<String, dynamic>,
        httpStatus: 403,
      );
      expect(e403.code, 'connect_inactive');
      final e402 = StripeApiError.fromJson(
        jsonDecode(err402) as Map<String, dynamic>,
        httpStatus: 402,
      );
      expect(e402.paywallTrigger, 'limit_stripe_products');
    });

    test('Edge client sends X-Werkly-Mock on onboard', () async {
      WerklySupabase.debugMarkConfigured(true);
      final raw = await rootBundle
          .loadString('assets/contracts/mocks/stripe-connect-onboard-200.json');
      final store = MonetizeMemoryStore();
      final client = StripeConnectClient(
        store: store,
        baseUrl: 'https://example.supabase.co',
        accessTokenProvider: () async => 'jwt',
        httpPost: (req) async {
          expect(req.uri.path, contains('/stripe-connect-onboard'));
          expect(req.headers['X-Werkly-Mock'], '1');
          expect(req.headers['Authorization'], 'Bearer jwt');
          return EdgeHttpResponse(statusCode: 200, body: raw);
        },
      );
      expect(client.isConfigured, isTrue);
      final res = await client.startOnboard();
      expect(res.stripeConnectStatus, ConnectStatus.pending);
    });
  });

  group('Hub attach product|tip refId', () {
    test('creates HubLink type product with refId', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      await repo.setConnectStatus(ConnectStatus.active);
      final product = (await repo.createProduct(
        name: 'Media Kit PDF',
        priceCents: 1500,
        live: true,
        isPro: false,
      ))
          .value!;

      final hubStore = HubMemoryStore();
      final hubRepo = LocalHubRepository(store: hubStore);
      final hub = await hubRepo.getOrCreateHub(userId: 'local-user');
      final link = await hubRepo.addLink(
        hubId: hub.id,
        type: HubLinkType.product,
        label: product.name,
        refId: product.id,
      );
      expect(link.type, HubLinkType.product);
      expect(link.refId, product.id);
      expect(link.label, 'Media Kit PDF');
    });
  });

  group('simulate sale fee + orders GET shape', () {
    test('records application_fee_cents from plan_limits', () async {
      final store = MonetizeMemoryStore();
      final repo = LocalMonetizeRepository(store: store);
      final sale = await repo.simulateSale(
        kind: SaleKind.tip,
        amountCents: 500,
        label: 'Tip',
        isPro: true,
      );
      expect(sale.applicationFeeCents, 25);
      expect(sale.feeBps, 500);
      expect(sale.toJson()['application_fee_cents'], 25);
      expect(sale.toJson()['kind'], 'tip');
    });
  });
}
