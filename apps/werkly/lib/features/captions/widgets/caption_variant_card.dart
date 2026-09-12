import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';

class CaptionVariantCard extends StatelessWidget {
  const CaptionVariantCard({
    super.key,
    required this.variant,
    required this.onCopy,
    required this.onFavorite,
    required this.onToCalendar,
    this.isFavorite = false,
  });

  final CaptionVariant variant;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onToCalendar;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final isHook = variant.kind == CaptionKind.hook;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(isHook ? 'Hook' : 'Caption'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isHook
                      ? Theme.of(context).colorScheme.tertiaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              variant.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: variant.body));
                    onCopy();
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Kopieren'),
                ),
                TextButton.icon(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
                  label: const Text('Favorit'),
                ),
                TextButton.icon(
                  onPressed: onToCalendar,
                  icon: const Icon(Icons.event, size: 18),
                  label: const Text('In Kalender'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
