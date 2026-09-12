import 'package:flutter/material.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';

class PlatformChipRow extends StatelessWidget {
  const PlatformChipRow({
    super.key,
    required this.selected,
    this.editable = false,
    this.onToggle,
  });

  final Set<PostPlatform> selected;
  final bool editable;
  final void Function(PostPlatform)? onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: PostPlatform.values.map((p) {
        final on = selected.contains(p);
        if (!editable) {
          if (!on) return const SizedBox.shrink();
          return Chip(
            label: Text(p.label, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }
        return FilterChip(
          label: Text(p.label),
          selected: on,
          onSelected: (_) => onToggle?.call(p),
        );
      }).toList(),
    );
  }
}
