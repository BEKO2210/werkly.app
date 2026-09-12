import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/router/route_paths.dart';

/// Shown when notification permission is denied — deep-link to S-06.
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({
    super.key,
    required this.visible,
  });

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: () => context.push(RoutePaths.permissionsNotifications),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.notifications_off_outlined, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erinnerungen aus — tippen, um Benachrichtigungen zu erlauben.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
