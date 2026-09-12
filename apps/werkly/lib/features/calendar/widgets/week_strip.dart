import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:werkly/features/calendar/domain/week_utils.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final start = WeekUtils.startOfIsoWeek(weekStart);
    final end = start.add(const Duration(days: 6));
    final kw = WeekUtils.isoWeekNumber(start);
    final range =
        '${DateFormat.MMMd('de_DE').format(start)} – ${DateFormat.MMMd('de_DE').format(end)}';

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Vorherige Woche',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                'KW $kw · $range',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Nächste Woche',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 7,
            itemBuilder: (context, i) {
              final day = start.add(Duration(days: i));
              final label = DateFormat.E('de_DE').format(day);
              final num = DateFormat.d().format(day);
              return Container(
                width: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11)),
                    Text(num, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
