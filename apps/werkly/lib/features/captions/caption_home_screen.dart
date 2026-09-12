import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/entitlements/quota_policy.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/domain/caption_validation.dart';
import 'package:werkly/features/captions/providers/caption_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/widgets/quota_banner.dart';

/// Screen-ID: S-20 — Caption home (topic, DE|EN, tone/platform, generate).
class CaptionHomeScreen extends ConsumerStatefulWidget {
  const CaptionHomeScreen({super.key});

  static const screenId = ScreenIds.captionHome;

  @override
  ConsumerState<CaptionHomeScreen> createState() => _CaptionHomeScreenState();
}

class _CaptionHomeScreenState extends ConsumerState<CaptionHomeScreen> {
  final _promptCtrl = TextEditingController();
  CaptionLanguage _language = CaptionLanguage.de;
  CaptionPlatformHint _platform = CaptionPlatformHint.neutral;
  String? _tone;
  String? _inlineError;
  bool _busy = false;

  static const _tones = <String>['locker', 'professionell', 'witzig', 'inspirierend'];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _inlineError = null;
      _busy = true;
    });

    final validation = CaptionValidation.validate(_promptCtrl.text);
    if (!validation.isValid) {
      setState(() {
        _inlineError = validation.errors.first;
        _busy = false;
      });
      return;
    }

    final quota = await ref.read(captionQuotaProvider.future);
    if (!mounted) return;
    if (QuotaPolicy.shouldBlockCaptionGenerate(
      isPro: quota.plan == 'pro',
      usedThisMonth: quota.used,
    )) {
      setState(() => _busy = false);
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCaptions}',
      );
      return;
    }

    final result = await ref.read(captionGenerateNotifierProvider.notifier).generate(
          prompt: validation.sanitizedPrompt,
          language: _language,
          tone: _tone,
          platform: _platform,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.softGated) {
      context.push(
        '${RoutePaths.paywall}?trigger=${QuotaPolicy.paywallTriggerCaptions}',
      );
      return;
    }
    if (result.validation != null && !result.validation!.isValid) {
      setState(() => _inlineError = result.validation!.errors.first);
      return;
    }
    if (result.error != null) {
      setState(() => _inlineError = result.error!.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!.error),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _generate,
          ),
        ),
      );
      return;
    }
    if (result.generation != null) {
      context.push(RoutePaths.texteResult(result.generation!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotaAsync = ref.watch(captionQuotaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Texte'),
        actions: [
          IconButton(
            tooltip: 'Favoriten',
            onPressed: () => context.push(RoutePaths.texteFavorites),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'S-20 · AI Caption & Hook',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          quotaAsync.when(
            data: (q) => QuotaBanner(
              used: q.used,
              limit: q.limit,
              label: '${q.used}/${q.limit} diesen Monat',
              trigger: QuotaPolicy.paywallTriggerCaptions,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptCtrl,
            maxLength: CaptionValidation.maxPromptLength,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Thema / Stichworte',
              hintText: 'z. B. Morgenroutine für Creator',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (_) {
              if (_inlineError != null) setState(() => _inlineError = null);
            },
          ),
          if (_inlineError != null) ...[
            Text(
              _inlineError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          Text('Sprache', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<CaptionLanguage>(
            segments: const [
              ButtonSegment(value: CaptionLanguage.de, label: Text('DE')),
              ButtonSegment(value: CaptionLanguage.en, label: Text('EN')),
            ],
            selected: {_language},
            onSelectionChanged: (s) => setState(() => _language = s.first),
          ),
          const SizedBox(height: 16),
          Text('Ton (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('—'),
                selected: _tone == null,
                onSelected: (_) => setState(() => _tone = null),
              ),
              ..._tones.map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: _tone == t,
                  onSelected: (_) => setState(() => _tone = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Plattform (optional)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: CaptionPlatformHint.values.map((p) {
              return FilterChip(
                label: Text(p.label),
                selected: _platform == p,
                onSelected: (_) => setState(() => _platform = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Generiere…' : 'Generieren'),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.texteFavorites),
            child: const Text('Favoriten öffnen'),
          ),
        ],
      ),
    );
  }
}
