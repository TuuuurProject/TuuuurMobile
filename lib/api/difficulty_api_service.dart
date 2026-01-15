import 'api_client.dart'; 

/// DTO pour une difficulté (ref.Difficulty_DFT)
class DifficultyDto {
  final int? id;
  final String label; // ex: "Facile", "Moyen", ...

  DifficultyDto({
    this.id,
    required this.label,
  });

  factory DifficultyDto.fromJson(Map<String, dynamic> j) {
    // On tolère plusieurs formats possibles côté API
    final dynamicId = j['id'] ?? j['difficultyId'];
    final id = _asInt(dynamicId);

    final label = _asString(
          j['label'] ?? j['name'] ?? j['title'],
        ) ??
        (id?.toString() ?? '');

    return DifficultyDto(
      id: id,
      label: label,
    );
  }

  // Helpers locaux (comme dans ThemeDto)
  static String? _asString(dynamic v) => v?.toString();

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// Client API pour /api/v1/difficulty
class DifficultyApi {
  final ApiClient _api;

  DifficultyApi(this._api);

  /// Récupère la liste des difficultés.
  ///
  /// Swagger : GET /api/v1/difficulty
  ///
  /// Tolère plusieurs enveloppes possibles :
  /// - { data: [...] }
  /// - { items: [...] }
  /// - { value: [...] }
  /// - { difficulties: [...] }
  /// Cette méthode nécessite l'authentification.
  Future<ApiResponse<List<DifficultyDto>>> getDifficulties() async {
    final res = await _api.getJson(
      '/api/v1/difficulty',
      auth: true,
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};

    // Même logique que ThemeApi : on cherche un tableau dans différentes clés
    dynamic list =
        root['data'] ?? root['items'] ?? root['value'] ?? root['difficulties'];

    if (list is! List) {
      list = const <dynamic>[];
    }

    final difficulties = <DifficultyDto>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        difficulties.add(DifficultyDto.fromJson(e));
      }
    }

    // Optionnel : les trier par Id si présent
    difficulties.sort((a, b) {
      final ai = a.id ?? 999999;
      final bi = b.id ?? 999999;
      return ai.compareTo(bi);
    });

    return ApiResponse.ok(
      difficulties,
      statusCode: res.statusCode,
    );
  }
}

/// Instance globale maintenue pour compatibilité - redirige vers ApiModule
/// Ne pas utiliser directement, préférer ApiModule.instance.difficultyApi
late final DifficultyApi difficultyApi;
