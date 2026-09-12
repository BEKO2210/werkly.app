import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/deals/domain/deal_csv.dart';
import 'package:werkly/features/deals/domain/deal_models.dart';
import 'package:werkly/features/deals/providers/deal_providers.dart';
import 'package:werkly/features/deals/widgets/deal_card.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/widgets/quota_banner.dart';

/// Screen-ID: S-40 — Deal list: filter, search, QuotaBanner open/5, FAB.
class DealListScreen extends ConsumerStatefulWidget {
  const DealListScreen({super.key});

  static const screenId = ScreenIds.dealList;

  @override
  ConsumerState<DealListScreen> createState() => _DealListScreenState();
}

class _DealListScreenState extends ConsumerState<DealListScreen> {
  DealStatus? _statusFilter;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Deal> _filtered(List<Deal> all) {
    var list = all;
    final f = _statusFilter;
    if (f != null) {
      list = list.where((d) => d.status == f).toList();
    }
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) => d.brand.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _openNew() {
    context.push(RoutePaths.dealsNew);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dealListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals'),
        actions: [
          IconButton(
            tooltip: 'CSV Export',
            onPressed: () => context.push(RoutePaths.dealsExport),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNew,
        tooltip: 'Neuer Deal',
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (state) {
          final filtered = _filtered(state.deals);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuotaBanner(
                used: state.openCount,
                limit: QuotaPolicy.freeOpenDeals,
                label: 'Offene Deals',
                trigger: QuotaPolicy.paywallTriggerDeals,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Marke suchen…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Alle'),
                        selected: _statusFilter == null,
                        onSelected: (_) =>
                            setState(() => _statusFilter = null),
                      ),
                    ),
                    ...DealStatus.pipeline.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(s.labelDe),
                          selected: _statusFilter == s,
                          onSelected: (_) => setState(() {
                            _statusFilter = _statusFilter == s ? null : s;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  DealCsv.taxDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyDeals(
                        hasAny: state.deals.isNotEmpty,
                        onCta: _openNew,
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(dealListNotifierProvider.notifier)
                            .refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final deal = filtered[i];
                            return DealCard(
                              deal: deal,
                              onTap: () =>
                                  context.push(RoutePaths.dealsId(deal.id)),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyDeals extends StatelessWidget {
  const _EmptyDeals({required this.hasAny, required this.onCta});

  final bool hasAny;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasAny
                  ? 'Keine Deals für diesen Filter'
                  : 'Keine Deals — Brand-Anfrage tracken',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Anfrage → Verhandlung → Gewonnen → Abgerechnet.\n'
              'Keine Buchhaltung — nur dein Deal-Tracker.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!hasAny) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCta,
                icon: const Icon(Icons.add),
                label: const Text('Brand-Anfrage tracken'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
