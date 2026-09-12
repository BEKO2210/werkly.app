/// Slug helpers for Free auto-slug + Pro custom slug (F3).
abstract final class HubSlug {
  /// Configurable public host for share URLs (placeholder OK).
  static const defaultPublicHost = 'https://werkly.app';

  static String buildPublicUrl(String slug, {String host = defaultPublicHost}) {
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return '$base/h/${slugify(slug)}';
  }

  static String buildMediaKitUrl(
    String slug, {
    String host = defaultPublicHost,
  }) {
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return '$base/h/${slugify(slug)}/kit';
  }

  /// Lowercase ASCII slug from display name; umlauts folded; empty → `hub`.
  static String slugify(String input) {
    var s = input.trim().toLowerCase();
    const fold = {
      'ä': 'ae',
      'ö': 'oe',
      'ü': 'ue',
      'ß': 'ss',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      buf.write(fold[ch] ?? ch);
    }
    s = buf.toString();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');
    s = s.replaceAll(RegExp(r'-{2,}'), '-');
    if (s.isEmpty) return 'hub';
    if (s.length > 48) s = s.substring(0, 48).replaceAll(RegExp(r'-$'), '');
    return s.isEmpty ? 'hub' : s;
  }

  /// Ensure uniqueness against [taken]; appends `-2`, `-3`, … or short suffix.
  static String uniqueSlug(
    String preferred, {
    required Set<String> taken,
    String? ignoreSlug,
  }) {
    final base = slugify(preferred);
    if (!taken.contains(base) || base == ignoreSlug) return base;
    for (var i = 2; i < 1000; i++) {
      final candidate = '$base-$i';
      if (!taken.contains(candidate) || candidate == ignoreSlug) {
        return candidate;
      }
    }
    return '$base-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}
