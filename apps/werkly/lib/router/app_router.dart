import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:werkly/features/auth/splash_auth_screen.dart';
import 'package:werkly/features/calendar/post_editor_screen.dart';
import 'package:werkly/features/calendar/reminder_settings_screen.dart';
import 'package:werkly/features/calendar/week_calendar_screen.dart';
import 'package:werkly/features/calendar/week_template_picker_screen.dart';
import 'package:werkly/features/captions/domain/caption_models.dart';
import 'package:werkly/features/captions/caption_favorites_screen.dart';
import 'package:werkly/features/captions/caption_home_screen.dart';
import 'package:werkly/features/captions/caption_result_screen.dart';
import 'package:werkly/features/deals/deal_editor_screen.dart';
import 'package:werkly/features/deals/deal_export_screen.dart';
import 'package:werkly/features/deals/deal_list_screen.dart';
import 'package:werkly/features/hub/hub_analytics_screen.dart';
import 'package:werkly/features/hub/hub_editor_screen.dart';
import 'package:werkly/features/hub/hub_link_editor_screen.dart';
import 'package:werkly/features/hub/hub_preview_screen.dart';
import 'package:werkly/features/hub/media_kit_editor_screen.dart';
import 'package:werkly/features/monetize/coming_soon_monetize_screen.dart';
import 'package:werkly/features/monetize/monetize_home_screen.dart';
import 'package:werkly/features/monetize/product_editor_screen.dart';
import 'package:werkly/features/monetize/sales_list_screen.dart';
import 'package:werkly/features/monetize/stripe_connect_screen.dart';
import 'package:werkly/features/monetize/tip_link_editor_screen.dart';
import 'package:werkly/features/onboarding/onboarding_first_caption_screen.dart';
import 'package:werkly/features/onboarding/onboarding_first_post_screen.dart';
import 'package:werkly/features/onboarding/onboarding_goal_screen.dart';
import 'package:werkly/features/onboarding/onboarding_hub_teaser_screen.dart';
import 'package:werkly/features/onboarding/onboarding_stripe_optional_screen.dart';
import 'package:werkly/features/paywall/paywall_screen.dart';
import 'package:werkly/features/permissions/notification_permission_screen.dart';
import 'package:werkly/features/settings/legal_web_screen.dart';
import 'package:werkly/features/settings/settings_screen.dart';
import 'package:werkly/features/shell/main_shell.dart';
import 'package:werkly/router/route_paths.dart';

/// Soft-auth redirect stub: never hard-blocks in MVP scaffold.
/// Default after auth stub → `/planen` (S-10 WeekCalendarScreen).
String? softAuthRedirect(BuildContext context, GoRouterState state) {
  // TODO: wire Supabase session. For scaffold, always allow.
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.auth,
    redirect: softAuthRedirect,
    routes: [
      // —— Auth & Onboarding ——
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.splashAuth,
        builder: (context, state) => const SplashAuthScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingGoal,
        name: RouteNames.onboardingGoal,
        builder: (context, state) => const OnboardingGoalScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingFirstCaption,
        name: RouteNames.onboardingFirstCaption,
        builder: (context, state) => const OnboardingFirstCaptionScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingFirstPost,
        name: RouteNames.onboardingFirstPost,
        builder: (context, state) => const OnboardingFirstPostScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingHub,
        name: RouteNames.onboardingHubTeaser,
        builder: (context, state) => const OnboardingHubTeaserScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingStripe,
        name: RouteNames.onboardingStripeOptional,
        builder: (context, state) => const OnboardingStripeOptionalScreen(),
      ),
      GoRoute(
        path: RoutePaths.permissionsNotifications,
        name: RouteNames.notificationPermission,
        builder: (context, state) => const NotificationPermissionScreen(),
      ),

      // —— RootShell tabs: Planen / Texte / Hub / Deals ——
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // TabPlanenStack
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.planen,
                name: RouteNames.weekCalendar,
                builder: (context, state) => const WeekCalendarScreen(),
                routes: [
                  GoRoute(
                    path: 'post',
                    name: RouteNames.postEditor,
                    builder: (context, state) {
                      final extra = state.extra;
                      final prefill = extra is CaptionPrefill ? extra : null;
                      return PostEditorScreen(captionPrefill: prefill);
                    },
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PostEditorScreen(
                          id: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'reminder-settings',
                    name: RouteNames.reminderSettings,
                    builder: (context, state) =>
                        const ReminderSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'templates',
                    name: RouteNames.weekTemplatePicker,
                    builder: (context, state) =>
                        const WeekTemplatePickerScreen(),
                  ),
                ],
              ),
            ],
          ),
          // TabTexteStack
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.texte,
                name: RouteNames.captionHome,
                builder: (context, state) => const CaptionHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'result/:generationId',
                    name: RouteNames.captionResult,
                    builder: (context, state) => CaptionResultScreen(
                      generationId:
                          state.pathParameters['generationId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'favorites',
                    name: RouteNames.captionFavorites,
                    builder: (context, state) =>
                        const CaptionFavoritesScreen(),
                  ),
                ],
              ),
            ],
          ),
          // TabHubStack
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.hub,
                name: RouteNames.hubEditor,
                builder: (context, state) => const HubEditorScreen(),
                routes: [
                  GoRoute(
                    path: 'link',
                    name: RouteNames.hubLinkEditor,
                    builder: (context, state) => const HubLinkEditorScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => HubLinkEditorScreen(
                          id: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'media-kit',
                    name: RouteNames.mediaKitEditor,
                    builder: (context, state) =>
                        const MediaKitEditorScreen(),
                  ),
                  GoRoute(
                    path: 'preview',
                    name: RouteNames.hubPreview,
                    builder: (context, state) => const HubPreviewScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    name: RouteNames.hubAnalytics,
                    builder: (context, state) => const HubAnalyticsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // TabDealsStack
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deals,
                name: RouteNames.dealList,
                builder: (context, state) => const DealListScreen(),
                routes: [
                  // Literal `new` before `:id` so it is not captured as id.
                  GoRoute(
                    path: 'new',
                    name: RouteNames.dealEditor,
                    builder: (context, state) => const DealEditorScreen(),
                  ),
                  GoRoute(
                    path: 'export',
                    name: RouteNames.dealExport,
                    builder: (context, state) => const DealExportScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    // Same Screen-ID S-41; path /deals/:id (name unique → use path push)
                    builder: (context, state) => DealEditorScreen(
                      id: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // —— MoreStack / overlays (no 5th tab) ——
      GoRoute(
        path: RoutePaths.monetize,
        name: RouteNames.monetizeHome,
        builder: (context, state) => const MonetizeHomeScreen(),
        routes: [
          GoRoute(
            path: 'connect',
            name: RouteNames.stripeConnect,
            builder: (context, state) => const StripeConnectScreen(),
          ),
          GoRoute(
            path: 'product',
            name: RouteNames.productEditor,
            builder: (context, state) => const ProductEditorScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ProductEditorScreen(
                  id: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'tip',
            name: RouteNames.tipLinkEditor,
            builder: (context, state) => const TipLinkEditorScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TipLinkEditorScreen(
                  id: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'sales',
            name: RouteNames.salesList,
            builder: (context, state) => const SalesListScreen(),
          ),
          GoRoute(
            path: 'soon',
            name: RouteNames.monetizeComingSoon,
            redirect: (context, state) => RoutePaths.monetize,
            builder: (context, state) => const ComingSoonMonetizeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.paywall,
        name: RouteNames.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '${RoutePaths.legal}/:doc',
        name: RouteNames.legalWeb,
        builder: (context, state) => LegalWebScreen(
          doc: state.pathParameters['doc'] ?? 'impressum',
        ),
      ),
    ],
  );
});
