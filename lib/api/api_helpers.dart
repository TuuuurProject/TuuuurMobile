/// Shared JSON parsing helpers for all API services.

/// Gets a value from JSON map.
dynamic get(Map<String, dynamic>? json, String key) => 
    json == null ? null : json[key];

/// Converts value to String.
String? asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

/// Converts value to int.
int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Converts value to bool.
bool? asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return null;
}

/// Converts value to DateTime. Handles dates with or without timezone.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is String) {
    try {
      final hasTzInfo =
          value.endsWith('Z') ||
          value.contains(RegExp(r'[+-]\d{2}:\d{2}$'));

      final parsed = DateTime.parse(value);

      if (hasTzInfo) {
        return parsed.toLocal();
      }

      // Backend sends naive UTC dates - reinterpret as UTC then convert to local
      final asUtc = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );

      return asUtc.toLocal();
    } catch (_) {
      return null;
    }
  }

  return null;
}

Map<String, dynamic>? asMap(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}

List<dynamic> asList(dynamic v) {
  if (v == null) return const [];
  return v is List ? v : const [];
}