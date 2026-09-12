import 'package:werkly/features/calendar/domain/calendar_post.dart';

/// Validation for F1 AC-2 / F1-T02:
/// title OR captionStub (≥1), ≥1 platform, date required.
class PostValidationResult {
  const PostValidationResult({required this.isValid, this.errors = const []});

  final bool isValid;
  final List<String> errors;

  factory PostValidationResult.ok() =>
      const PostValidationResult(isValid: true);

  factory PostValidationResult.fail(List<String> errors) =>
      PostValidationResult(isValid: false, errors: errors);
}

abstract final class PostValidator {
  static PostValidationResult validate({
    String? title,
    String? captionStub,
    Set<PostPlatform>? platforms,
    DateTime? scheduledAt,
  }) {
    final errors = <String>[];
    final hasTitle = title != null && title.trim().isNotEmpty;
    final hasCaption =
        captionStub != null && captionStub.trim().isNotEmpty;
    if (!hasTitle && !hasCaption) {
      errors.add('Titel oder Caption-Stub erforderlich.');
    }
    if (platforms == null || platforms.isEmpty) {
      errors.add('Mindestens eine Plattform wählen.');
    }
    if (scheduledAt == null) {
      errors.add('Datum/Zeit erforderlich.');
    }
    if (errors.isEmpty) return PostValidationResult.ok();
    return PostValidationResult.fail(errors);
  }
}
