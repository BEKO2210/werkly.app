import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/config/app_flags.dart';
import 'package:werkly/core/auth/session_providers.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/theme/app_spacing.dart';

/// Screen-ID: S-00 — SplashAuth · live Supabase or labeled mock.
class SplashAuthScreen extends ConsumerStatefulWidget {
  const SplashAuthScreen({super.key});

  static const screenId = ScreenIds.splashAuth;

  @override
  ConsumerState<SplashAuthScreen> createState() => _SplashAuthScreenState();
}

class _SplashAuthScreenState extends ConsumerState<SplashAuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _goAfterAuth() async {
    if (!mounted) return;
    context.go(RoutePaths.planen);
  }

  Future<void> _mockContinue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .mockSignIn(email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim());
      await _goAfterAuth();
    } catch (e) {
      setState(() => _error = 'Mock-Login fehlgeschlagen');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _passwordSignIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'E-Mail und Passwort eingeben');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authSessionProvider.notifier).signInPassword(
            email: email,
            password: password,
          );
      await _goAfterAuth();
    } catch (e) {
      setState(() => _error = 'Anmeldung fehlgeschlagen');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _magicLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'E-Mail für Magic Link eingeben');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .signInMagicLink(email: email);
      if (AppFlags.mockAuth) {
        await _goAfterAuth();
      } else {
        setState(() =>
            _info = 'Magic Link gesendet — E-Mail prüfen und App erneut öffnen.');
      }
    } catch (e) {
      setState(() => _error = 'Magic Link konnte nicht gesendet werden');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = AppFlags.liveAuth;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Icon(Icons.auto_awesome, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Werkly',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              live
                  ? 'Mit E-Mail anmelden'
                  : 'Gast / Mock-Login (Supabase nicht konfiguriert)',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!live)
              Card(
                color: scheme.secondaryContainer,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    'Mock-Auth aktiv — für Live: '
                    '--dart-define=SUPABASE_URL=… '
                    '--dart-define=SUPABASE_ANON_KEY=…',
                    style: text.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
            ),
            if (live) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            if (_info != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_info!, style: text.bodySmall),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (live) ...[
              FilledButton(
                onPressed: _busy ? null : _passwordSignIn,
                child: Text(_busy ? '…' : 'Weiter mit E-Mail'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _busy ? null : _magicLink,
                child: const Text('Magic Link senden'),
              ),
            ] else
              FilledButton(
                onPressed: _busy ? null : _mockContinue,
                child: Text(_busy ? '…' : 'Weiter als Gast (Mock)'),
              ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Impressum · Datenschutz',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.outline),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.legalDoc('impressum')),
              child: const Text('Rechtliches'),
            ),
          ],
        ),
      ),
    );
  }
}
