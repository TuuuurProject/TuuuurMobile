import '../api_client.dart';
import '../api_helpers.dart';
import 'auth_models.dart';

/// Authentication + Me endpoints.
class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  ApiResponse<AuthSessionDto> _buildAuthSession(
    Map<String, dynamic> m,
    int? statusCode, {
    bool defaultIsGoogleUser = false,
  }) {
    final userData = get(m, 'user');
    final tokenData = get(m, 'token');

    final user = UserDto.fromJson(
      userData is Map ? Map<String, dynamic>.from(userData) : null,
    );
    final token = AuthTokenDto.fromJson(
      tokenData is Map ? Map<String, dynamic>.from(tokenData) : null,
    );
    final isGoogleUser =
        (get(m, 'isGoogleUser') as bool?) ?? defaultIsGoogleUser;

    return ApiResponse.ok(
      AuthSessionDto(
        user: user,
        token: token,
        isGoogleUser: isGoogleUser,
        raw: m,
      ),
      statusCode: statusCode,
    );
  }

  Future<ApiResponse<RegisterResultDto>> register({
    required String email,
    required String nickName,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/api/v1/Auth/register',
      body: {
        'email': email.trim(),
        'nickName': nickName.trim(),
        'password': password,
      },
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final map = res.data ?? <String, dynamic>{};
    final verificationId = asString(get(map, 'verificationId'));
    final delivery = asString(get(map, 'delivery')) ?? 'email';
    return ApiResponse.ok(
      RegisterResultDto(
        verificationRequired: true,
        verificationId: verificationId,
        delivery: delivery,
        raw: map,
      ),
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<bool>> login({
    required String login,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/login',
      body: {'login': login.trim(), 'password': password},
    );

    if (res.statusCode == 200) {
      return ApiResponse.ok(true, statusCode: res.statusCode);
    }

    String? message = res.message;

    if (res.statusCode == 401 &&
        res.raw is List &&
        (res.raw as List).isNotEmpty) {
      final first = (res.raw as List).first;
      if (first is Map && first['description'] is String) {
        message = first['description'] as String;
      }
    }

    return ApiResponse.err(
      message: message ?? 'Échec de la connexion.',
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<AuthSessionDto>> loginWithGoogle({
    required String idToken,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/google',
      body: {'token': idToken},
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final m = res.data ?? <String, dynamic>{};
    return _buildAuthSession(m, res.statusCode, defaultIsGoogleUser: true);
  }

  Future<ApiResponse<AuthSessionDto>> loginAsGuest({
    required String nickName,
  }) async {
    final res = await _api.postJson(
      '/api/v1/Auth/invited',
      body: {'nickName': nickName.trim()},
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final m = res.data ?? <String, dynamic>{};
    return _buildAuthSession(m, res.statusCode);
  }

  Future<ApiResponse<bool>> passwordForgot({required String login}) async {
    final res = await _api.postJson(
      '/api/v1/auth/password/forgot',
      body: {'login': login.trim()},
    );

    if (res.statusCode == 200) {
      return ApiResponse.ok(true, statusCode: res.statusCode);
    }
    return ApiResponse.err(
      message: res.message ?? 'Impossible de lancer la procédure.',
      statusCode: res.statusCode,
      raw: res.raw,
    );
  }

  Future<ApiResponse<bool>> passwordReset({
    required String login,
    required String code,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/password/reset',
      body: {'login': login.trim(), 'password': password, 'code': code.trim()},
    );

    if (res.statusCode == 200) {
      return ApiResponse.ok(true, statusCode: res.statusCode);
    }
    return ApiResponse.err(
      message: res.message ?? 'Réinitialisation impossible.',
      statusCode: res.statusCode,
      raw: res.raw,
    );
  }

  Future<ApiResponse<AuthSessionDto>> verify2fa({
    required String login,
    required String code,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/2fa/verify',
      body: {'login': login.trim(), 'code': code.trim()},
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final m = res.data ?? <String, dynamic>{};
    return _buildAuthSession(m, res.statusCode);
  }

  /// Refresh auth token.
  Future<ApiResponse<AuthSessionDto>> refreshToken({
    required String bearer,
    required String refreshToken,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/refresh',
      body: {'bearer': bearer, 'refreshToken': refreshToken},
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final m = res.data ?? <String, dynamic>{};
    return _buildAuthSession(m, res.statusCode);
  }

  /// Get current user info. Requires authentication via ApiClient.
  Future<ApiResponse<UserDto>> me() async {
    final res = await _api.getJson('/api/v1/me', auth: true);
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final m = res.data ?? <String, dynamic>{};
    return ApiResponse.ok(UserDto.fromJson(m), statusCode: res.statusCode);
  }

  /// Update avatar (base64). Requires authentication via ApiClient.
  Future<ApiResponse<bool>> updateAvatarBase64({required String base64}) async {
    final res = await _api.putJson(
      '/api/v1/me/avatar',
      auth: true,
      body: {'avatar': base64},
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    final success = (res.data?['success'] as bool?) ?? true;
    return success
        ? ApiResponse.ok(true, statusCode: res.statusCode)
        : ApiResponse.err(message: res.data?['message']?.toString());
  }

  /// Change user password. Requires authentication via ApiClient.
  Future<ApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    };
    final res = await _api.putJson(
      '/api/v1/me/change-password',
      auth: true,
      body: body,
    );
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }

  /// Delete user account. Requires authentication via ApiClient.
  Future<ApiResponse<bool>> deleteMe() async {
    final res = await _api.delete('/api/v1/me', auth: true);
    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }

  /// Update user nickname. Requires authentication via ApiClient.
  Future<ApiResponse<UserDto>> updateNickname({
    required String nickname,
  }) async {
    final res = await _api.putJson(
      '/api/v1/me/nickname',
      auth: true,
      body: {'nickname': nickname.trim()},
    );

    if (!res.ok) {
      return ApiResponse.err(
        message: res.message,
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final m = res.data ?? <String, dynamic>{};

    final success = (m['success'] as bool?) ?? true;
    if (success != true) {
      String? msg = m['message']?.toString();

      final errors = m['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['description'] != null) {
          msg = first['description'].toString();
        }
      }

      return ApiResponse.err(
        message: msg ?? 'Échec de la mise à jour du pseudo.',
        statusCode: res.statusCode,
        raw: m,
      );
    }

    Map<String, dynamic>? userMap;
    final value = m['value'];

    if (value is List && value.isNotEmpty && value.first is Map) {
      userMap = Map<String, dynamic>.from(value.first as Map);
    } else if (value is Map) {
      userMap = Map<String, dynamic>.from(value);
    }

    final user = UserDto.fromJson(userMap);
    return ApiResponse.ok(user, statusCode: res.statusCode);
  }
}
