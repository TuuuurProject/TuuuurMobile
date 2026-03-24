import '../api_client.dart';
import 'theme_models.dart';

class ThemeApi {
  final ApiClient _api;
  ThemeApi(this._api);

  Future<ApiResponse<List<ThemeDto>>> getThemes() async {
    final res = await _api.getJson('/api/v1/theme', auth: true);
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final root = res.data ?? <String, dynamic>{};

    // ApiClient wraps array responses in data['data']
    dynamic list =
        root['data'] ?? root['items'] ?? root['value'] ?? root['themes'];
    if (list is! List) {
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
