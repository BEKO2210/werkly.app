import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/calendar/widgets/platform_chips.dart';
import 'package:werkly/features/calendar/widgets/status_pill.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final CalendarPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm('de_DE').format(post.scheduledAt);
    final title = (post.title?.trim().isNotEmpty == true)
        ? post.title!
        : (post.captionStub ?? 'Ohne Titel');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            PlatformChipRow(selected: post.platforms),
            const SizedBox(height: 4),
            Text(
              '$time · Reminder · manuell posten',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: StatusPill(status: post.status),
        isThreeLine: true,
      ),
    );
  }
}
