import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/core/auth/session_providers.dart';
import 'package:werkly/core/config/app_flags.dart';
import 'package:werkly/core/entitlements/entitlements.dart';
import 'package:werkly/router/route_paths.dart';
import 'package:werkly/router/screen_ids.dart';
import 'package:werkly/ui/theme/app_spacing.dart';

/// Screen-ID: S-61 — Settings. Konto · Abo · KI-Key · Legal.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const screenId = ScreenIds.settings;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _useOwnKey = true;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    setState(() => _saving = true);
    final store = ref.read(llmKeyStoreProvider);
    // Never log _keyCtrl.text
    await store.save(_keyCtrl.text);
    _keyCtrl.clear();
    ref.invalidate(llmKeyMaskedProvider);
    ref.invalidate(llmKeyPresentProvider);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API-Key gespeichert (nur auf diesem Gerät)')),
      );
    }
  }

  Future<void> _clearKey() async {
    await ref.read(llmKeyStoreProvider).clear();
    _keyCtrl.clear();
    ref.invalidate(llmKeyMaskedProvider);
    ref.invalidate(llmKeyPresentProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API-Key gelöscht')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final isPro = ref.watch(isProProvider);
    final maskedAsync = ref.watch(llmKeyMaskedProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionHeader('Konto'),
          ListTile(
            title: const Text('Account'),
            subtitle: Text(
              '${session.emailOrGuestLabel} · ${isPro ? "Pro" : "Free"}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePaths.account),
          ),
          ListTile(
            title: const Text('Session'),
            subtitle: Text(
              session.isAuthenticated
                  ? (session.isMock ? 'Gast / Mock' : 'Angemeldet (Live)')
                  : 'Nicht angemeldet',
            ),
          ),
          const Divider(),
          const _SectionHeader('Abonnement'),
          const ListTile(
            title: Text('Dein Pro-Abo'),
            subtitle: Text('Werkly Pro 9,99 €/Mo · Verwaltet über Google Play'),
          ),
          ListTile(
            title: const Text('Pro freischalten'),
            subtitle: const Text('S-60 · App-Abo, nicht Stripe'),
            onTap: () => context.push(RoutePaths.paywall),
          ),
          ListTile(
            title: const Text('Käufe wiederherstellen'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restore folgt (RevenueCat)')),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('Deine Verkäufe'),
          const ListTile(
            title: Text('Stripe Connect'),
            subtitle: Text('Creator-Sales · kein App-Abo'),
          ),
          ListTile(
            title: const Text('Monetize / Stripe'),
            subtitle: const Text('S-50 · Produkt, Tip, Umsätze'),
            onTap: () => context.push(RoutePaths.monetize),
          ),
          const Divider(),
          const _SectionHeader('KI / Captions'),
          SwitchListTile(
            title: const Text('Eigenen Key nutzen'),
            subtitle: const Text(
              'Key bleibt auf dem Gerät · nie in Logs. '
              'Header X-Werkly-LLM-Key an Edge.',
            ),
            value: _useOwnKey,
            onChanged: (v) => setState(() => _useOwnKey = v),
          ),
          if (_useOwnKey) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  maskedAsync.when(
                    data: (masked) => masked == null
                        ? Text(
                            'Kein Key hinterlegt',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        : Text(
                            'Gespeichert: $masked',
                            style: text.bodySmall,
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _keyCtrl,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'API-Key (optional)',
                      hintText: 'Einfügen…',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Anzeigen' : 'Verbergen',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _saveKey,
                          child: Text(_saving ? '…' : 'Speichern'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: _clearKey,
                        child: const Text('Löschen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppFlags.mockCaptions
                        ? 'Captions: Mock (Supabase/Edge nicht konfiguriert)'
                        : 'Captions: Edge live möglich (JWT ± BYOK)',
                    style: text.bodySmall?.copyWith(color: scheme.outline),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
          const Divider(),
          const _SectionHeader('Rechtliches'),
          ListTile(
            title: const Text('Impressum'),
            onTap: () => context.push(RoutePaths.legalDoc('impressum')),
          ),
          ListTile(
            title: const Text('Datenschutz'),
            onTap: () => context.push(RoutePaths.legalDoc('privacy')),
          ),
          const Divider(),
          const _SectionHeader('Über'),
          ListTile(
            title: const Text('Werkly'),
            subtitle: Text(
              '0.1.0+1 · com.werkly.app\n'
              'Flags: mockAuth=${AppFlags.mockAuth} '
              'mockCaptions=${AppFlags.mockCaptions} '
              'mockStripe=${AppFlags.mockStripe} '
              'useLiveCaptions=${AppFlags.useLiveCaptions}',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
