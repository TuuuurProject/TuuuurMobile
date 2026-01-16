/// Helpers de parsing partagés pour tous les services API.
/// Ces fonctions permettent de parser de manière sûre les données JSON.

/// Récupère une valeur dans un Map JSON.
dynamic get(Map<String, dynamic>? json, String key) => 
    json == null ? null : json[key];

/// Convertit une valeur en String.
String? asString(dynamic value) => value?.toString();

/// Convertit une valeur en int.
int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Convertit une valeur en bool.
bool? asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return null;
}

/// Convertit une valeur en DateTime.
/// Gère les dates avec ou sans fuseau horaire.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is String) {
    try {
      // Si la string contient déjà un fuseau (Z ou +hh:mm / -hh:mm en fin de chaîne),
      // on laisse Dart gérer normalement et on passe juste en local.
      final hasTzInfo =
          value.endsWith('Z') ||
          value.contains(RegExp(r'[+-]\d{2}:\d{2}$'));

      final parsed = DateTime.parse(value);

      if (hasTzInfo) {
        return parsed.toLocal();
      }

      // Le back envoie une date en UTC "naïf" (sans info de fuseau).
      // On réinterprète l'heure lue comme UTC, puis on convertit en local.
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
