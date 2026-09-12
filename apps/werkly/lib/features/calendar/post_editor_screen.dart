import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/calendar/domain/calendar_post.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/calendar/providers/calendar_providers.dart';
import 'package:werkly/features/calendar/widgets/platform_chips.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';

/// Screen-ID: S-11 — Create/edit calendar post (usable CRUD).
class PostEditorScreen extends ConsumerStatefulWidget {
  const PostEditorScreen({super.key, this.id, this.captionPrefill});

  /// clientId when editing.
  final String? id;

  /// F2 → F1 deep-link prefill (go_router `extra` or explicit).
  final CaptionPrefill? captionPrefill;

  static const screenId = ScreenIds.postEditor;

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _platforms = <PostPlatform>{};
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  int _reminderOffset = ReminderOffsets.defaultMinutes;
  PostStatus _status = PostStatus.planned;
  bool _loading = false;
  bool _hydrated = false;
  String? _error;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    } else {
      final pre = widget.captionPrefill;
      if (pre != null) {
        _captionCtrl.text = pre.captionPrefill;
        final hint = pre.platformHint;
        if (hint != null && hint != CaptionPlatformHint.neutral) {
          _platforms.add(switch (hint) {
            CaptionPlatformHint.ig => PostPlatform.ig,
            CaptionPlatformHint.tiktok => PostPlatform.tiktok,
            CaptionPlatformHint.yt => PostPlatform.youtube,
            CaptionPlatformHint.other => PostPlatform.other,
            CaptionPlatformHint.neutral => PostPlatform.other,
          });
        }
      }
      _hydrated = true;
    }
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(calendarRepositoryProvider);
    final post = await repo.getByClientId(widget.id!) ??
        await repo.getById(widget.id!);
    if (!mounted) return;
    if (post != null) {
      _titleCtrl.text = post.title ?? '';
      _captionCtrl.text = post.captionStub ?? '';
      _platforms
        ..clear()
        ..addAll(post.platforms);
      _scheduledAt = post.scheduledAt;
      _reminderOffset = post.reminderOffsetMinutes;
      _status = post.status;
    }
    setState(() => _hydrated = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(calendarNotifierProvider.notifier).savePost(
          existingClientId: _isEdit ? widget.id : null,
          title: _titleCtrl.text,
          captionStub: _captionCtrl.text,
          platforms: Set.of(_platforms),
          scheduledAt: _scheduledAt,
          reminderOffsetMinutes: _reminderOffset,
          status: _status,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCalendar}',
      );
      return;
    }
    if (result.validation != null && !result.validation!.isValid) {
      setState(() => _error = result.validation!.errors.join('\n'));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Geplant — Reminder erinnert dich. Du postest manuell.',
        ),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.planen);
    }
  }

  Future<void> _setStatus(PostStatus status) async {
    if (!_isEdit) {
      setState(() => _status = status);
      return;
    }
    await ref
        .read(calendarNotifierProvider.notifier)
        .setStatus(widget.id!, status);
    setState(() => _status = status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status: ${status.labelDe}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dtLabel = DateFormat('EEE, d. MMM yyyy · HH:mm', 'de_DE')
        .format(_scheduledAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Post bearbeiten' : 'Neuer Post'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'S-11 · Reminder · manuell posten',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titel',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionCtrl,
            decoration: const InputDecoration(
              labelText: 'Caption-Stub',
              helperText: 'Titel oder Caption-Stub erforderlich',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Text('Plattformen', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          PlatformChipRow(
            selected: _platforms,
            editable: true,
            onToggle: (p) {
              setState(() {
                if (_platforms.contains(p)) {
                  _platforms.remove(p);
                } else {
                  _platforms.add(p);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Datum & Zeit'),
            subtitle: Text(dtLabel),
            trailing: const Icon(Icons.event),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 8),
          Text('Reminder-Offset',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReminderOffsets.allowed.map((m) {
              return ChoiceChip(
                label: Text('$m Min'),
                selected: _reminderOffset == m,
                onSelected: (_) => setState(() => _reminderOffset = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lokaler Reminder · kein Auto-Publish',
            style: TextStyle(fontSize: 12),
          ),
          if (_isEdit) ...[
            const Divider(height: 32),
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PostStatus.values.map((s) {
                return ChoiceChip(
                  label: Text(s.labelDe),
                  selected: _status == s,
                  onSelected: (_) => _setStatus(s),
                );
              }).toList(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: const Text('Speichern'),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.planenReminderSettings),
            child: const Text('Reminder-Einstellungen'),
          ),
        ],
      ),
    );
  }
}
