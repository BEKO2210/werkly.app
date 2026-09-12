/// Route path + go_router name constants — Arch §4 EXACT map.
abstract final class RoutePaths {
  // Auth & Onboarding
  static const auth = '/auth';
  static const onboardingGoal = '/onboarding/goal';
  static const onboardingFirstCaption = '/onboarding/first-caption';
  static const onboardingFirstPost = '/onboarding/first-post';
  static const onboardingHub = '/onboarding/hub';
  static const onboardingStripe = '/onboarding/stripe';
  static const permissionsNotifications = '/permissions/notifications';

  // F1 Planen (TabPlanenStack)
  static const planen = '/planen';
  static const planenPost = '/planen/post';
  static const planenReminderSettings = '/planen/reminder-settings';
  static const planenTemplates = '/planen/templates';

  // F2 Texte (TabTexteStack)
  static const texte = '/texte';
  static const texteFavorites = '/texte/favorites';

  // F3 Hub (TabHubStack)
  static const hub = '/hub';
  static const hubLink = '/hub/link';
  static const hubMediaKit = '/hub/media-kit';
  static const hubPreview = '/hub/preview';
  static const hubAnalytics = '/hub/analytics';

  // F4 Deals (TabDealsStack)
  static const deals = '/deals';
  static const dealsNew = '/deals/new';
  static const dealsExport = '/deals/export';

  // F5 + System (MoreStack / overlays)
  static const monetize = '/more/monetize';
  static const monetizeConnect = '/more/monetize/connect';
  static const monetizeProduct = '/more/monetize/product';
  static const monetizeTip = '/more/monetize/tip';
  static const monetizeSales = '/more/monetize/sales';
  static const monetizeSoon = '/more/monetize/soon';
  static const paywall = '/paywall';
  static const settings = '/more/settings';
  static const legal = '/more/legal';

  /// Path helpers for param routes.
  static String planenPostId(String id) => '/planen/post/$id';
  static String texteResult(String generationId) =>
      '/texte/result/$generationId';
  static String hubLinkId(String id) => '/hub/link/$id';
  static String dealsId(String id) => '/deals/$id';
  static String monetizeProductId(String id) => '/more/monetize/product/$id';
  static String monetizeTipId(String id) => '/more/monetize/tip/$id';
  static String legalDoc(String doc) => '/more/legal/$doc';
}

/// go_router route `name` values from Arch §4.
abstract final class RouteNames {
  static const splashAuth = 'splashAuth';
  static const onboardingGoal = 'onboardingGoal';
  static const onboardingFirstCaption = 'onboardingFirstCaption';
  static const onboardingFirstPost = 'onboardingFirstPost';
  static const onboardingHubTeaser = 'onboardingHubTeaser';
  static const onboardingStripeOptional = 'onboardingStripeOptional';
  static const notificationPermission = 'notificationPermission';
  static const weekCalendar = 'weekCalendar';
  static const postEditor = 'postEditor';
  static const reminderSettings = 'reminderSettings';
  static const weekTemplatePicker = 'weekTemplatePicker';
  static const captionHome = 'captionHome';
  static const captionResult = 'captionResult';
  static const captionFavorites = 'captionFavorites';
  static const hubEditor = 'hubEditor';
  static const hubLinkEditor = 'hubLinkEditor';
  static const mediaKitEditor = 'mediaKitEditor';
  static const hubPreview = 'hubPreview';
  static const hubAnalytics = 'hubAnalytics';
  static const dealList = 'dealList';
  static const dealEditor = 'dealEditor';
  static const dealExport = 'dealExport';
  static const monetizeHome = 'monetizeHome';
  static const stripeConnect = 'stripeConnect';
  static const productEditor = 'productEditor';
  static const tipLinkEditor = 'tipLinkEditor';
  static const salesList = 'salesList';
  static const paywall = 'paywall';
  static const settings = 'settings';
  static const legalWeb = 'legalWeb';
  static const monetizeComingSoon = 'monetizeComingSoon';
}
