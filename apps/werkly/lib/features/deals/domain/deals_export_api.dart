/// OpenAPI shapes for Edge `GET /functions/v1/deals-export` (Pro).
class DealsExportResponse {
  const DealsExportResponse({
    required this.csv,
    this.contentType = 'text/csv',
    this.rowCount = 0,
    this.source = 'local',
  });

  final String csv;
  final String contentType;
  final int rowCount;

  /// `edge` | `local` — which path produced the CSV.
  final String source;

  factory DealsExportResponse.fromJson(Map<String, dynamic> j) {
    return DealsExportResponse(
      csv: (j['csv'] as String?) ?? '',
      contentType: (j['content_type'] ?? j['contentType'] ?? 'text/csv') as String,
      rowCount: (j['row_count'] ?? j['rowCount'] ?? 0) as int,
      source: (j['source'] as String?) ?? 'edge',
    );
  }

  Map<String, dynamic> toJson() => {
        'csv': csv,
        'content_type': contentType,
        'row_count': rowCount,
        'source': source,
      };
}

class DealsExportApiError implements Exception {
  const DealsExportApiError({
    required this.error,
    this.code = 'upstream_unavailable',
    this.httpStatus = 503,
    this.details,
  });

  final String error;
  final String code;
  final int httpStatus;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => httpStatus == 401;
  bool get isPaymentRequired => httpStatus == 402;
  bool get isForbidden => httpStatus == 403;

  factory DealsExportApiError.fromJson(
    Map<String, dynamic> j, {
    required int httpStatus,
  }) {
    return DealsExportApiError(
      error: (j['error'] as String?) ?? 'Export fehlgeschlagen',
      code: (j['code'] as String?) ?? 'error',
      httpStatus: httpStatus,
      details: j['details'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'DealsExportApiError($httpStatus $code: $error)';
}
