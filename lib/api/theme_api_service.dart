import 'api_client.dart';

class ThemeItemDto {
  final int? id;
  final String icon;   // ex: "gamepad", "fa-gamepad", "FontAwesomeIcons.music"
  final String label;  // ex: "Général"

  ThemeItemDto({this.id, required this.icon, required this.label});

  factory ThemeItemDto.fromJson(Map<String, dynamic> j) => ThemeItemDto(
        id: (j['id'] is int) ? j['id'] as int : int.tryParse('${j['id']}'),
        icon: (j['icon'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
      );
}

class ThemeDto {
  final int? id;
  final String key;  
  final String name; 
  final String? description;
  final String? icon; 

  ThemeDto({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    this.icon,
  });

  factory ThemeDto.fromJson(Map<String, dynamic> j) {
    // on tolère plusieurs clés possibles
    final dynamicId = j['id'] ?? j['themeId'];
    final id = _asInt(dynamicId);
    final code = _asString(j['code'] ?? j['key'] ?? j['slug']) ?? (id?.toString() ?? '');
    final name = _asString(j['name'] ?? j['label'] ?? j['title']) ?? code;
    final desc = _asString(j['description'] ?? j['details']);
    final icon = _asString(j['icon'] ?? j['faIcon'] ?? j['iconName']);

    return ThemeDto(
      id: id,
      key: code,
      name: name,
      description: desc,
      icon: icon,
    );
  }

  // helpers locaux
  static String? _asString(dynamic v) => v?.toString();
  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}


class ThemeApi {
  final ApiClient _api;
  ThemeApi(this._api);

  /// Récupère la liste des thèmes.
  /// Cette méthode nécessite l'authentification.
  Future<ApiResponse<List<ThemeDto>>> getThemes() async {
    final res = await _api.getJson('/api/v1/theme', auth: true);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }

    final root = res.data ?? <String, dynamic>{};

    // L’ApiClient met les réponses "array" dans data['data']
    dynamic list = root['data'] ?? root['items'] ?? root['value'] ?? root['themes'];
    if (list is! List) {
      // si le backend renvoie directement un tableau, ApiClient l’a mis dans {'data': <array>}
      // sinon, fallback vide pour éviter un crash.
      list = const <dynamic>[];
    }

    final items = <ThemeDto>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        items.add(ThemeDto.fromJson(e));
      }
    }
    return ApiResponse.ok(items, statusCode: res.statusCode);
  }
}

// Instance globale maintenue pour compatibilité - redirige vers ApiModule
// Ne pas utiliser directement, préférer ApiModule.instance.themeApi
late final ThemeApi themeApi;
