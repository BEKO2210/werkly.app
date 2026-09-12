/// Prompt validation + policy reject (GENERATE-CAPTION-V1 + AC F2 safety).
abstract final class CaptionValidation {
  static const maxPromptLength = 500;

  /// Contract mock: reject if prompt contains "BLOCK" (case-insensitive).
  static const mockBlockToken = 'block';

  /// Simple DACH/EN blocklist — reject before API call (inline error, no call).
  static const abusiveKeywords = <String>[
    'block', // GENERATE-CAPTION-V1 mock policy
    'kill yourself',
    'kys',
    'nigger',
    'nigga',
    'faggot',
    'hurensohn',
    'fotze',
    'schwuchtel',
    'heil hitler',
    'gas the',
    'rape ',
    'vergewaltig',
  ];

  static CaptionValidationResult validate(String? prompt) {
    final errors = <String>[];
    final trimmed = prompt?.trim() ?? '';
    if (trimmed.isEmpty) {
      errors.add('Bitte ein Thema oder Stichworte eingeben.');
    } else if (trimmed.length > maxPromptLength) {
      errors.add('Max. $maxPromptLength Zeichen.');
    } else {
      final lower = trimmed.toLowerCase();
      for (final bad in abusiveKeywords) {
        if (lower.contains(bad)) {
          errors.add(
            'Dieser Prompt verstößt gegen unsere Nutzungsregeln.',
          );
          break;
        }
      }
    }
    return CaptionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedPrompt: trimmed,
      code: errors.isEmpty
          ? null
          : (trimmed.isEmpty ? 'validation_error' : 'policy_reject'),
    );
  }
}

class CaptionValidationResult {
  const CaptionValidationResult({
    required this.isValid,
    required this.errors,
    required this.sanitizedPrompt,
    this.code,
  });

  final bool isValid;
  final List<String> errors;
  final String sanitizedPrompt;
  final String? code;
}
