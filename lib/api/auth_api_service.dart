import 'api_client.dart'; // <-- au lieu d'avoir ApiClient/ApiResponse définis ici

/// Helpers parsing simples
dynamic _get(Map<String, dynamic>? j, String key) => j == null ? null : j[key];
String? _asString(dynamic v) => v == null ? null : v.toString();
int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
bool? _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is num) return v != 0;
  return null;
}
DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Résultat d'inscription (2FA attendu).
class RegisterResult {
  final bool verificationRequired;
  final String? verificationId;
  final String delivery; // 'email'/'sms'
  final Map<String, dynamic> raw;
  const RegisterResult({
    required this.verificationRequired,
    required this.delivery,
    required this.raw,
    this.verificationId,
  });
}

class LoginResult {
  final bool requires2fa;
  final AuthSession? session;
  final String? delivery;   // 'email' / 'sms' ...
  final String? emailHint;  // si le back renvoie une cible (ex: adresse)
  const LoginResult({
    required this.requires2fa,
    this.session,
    this.delivery,
    this.emailHint,
  });
}

/// Modèles pour session / utilisateur.
class UserDto {
  final int? id;
  final String? nickName;
  final String? email;
  final String? avatar;
  final bool? isAdmin;
  final bool? isNew;

  UserDto({
    this.id,
    this.nickName,
    this.email,
    this.avatar,
    this.isAdmin,
    this.isNew,
  });

  factory UserDto.fromJson(Map<String, dynamic>? j) {
    return UserDto(
      id: _asInt(_get(j, 'id')),
      nickName: _asString(_get(j, 'nickName')),
      email: _asString(_get(j, 'email')),
      avatar: _asString(_get(j, 'avatar')),
      isAdmin: _asBool(_get(j, 'isAdmin')),
      isNew: _asBool(_get(j, 'isNew')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickName': nickName,
        'email': email,
        'avatar': avatar,
        'isAdmin': isAdmin,
        'isNew': isNew,
      };
}

class AuthToken {
  final String token;
  final DateTime? validFrom;
  final DateTime? validTo;

  AuthToken({required this.token, this.validFrom, this.validTo});

  factory AuthToken.fromJson(Map<String, dynamic>? j) => AuthToken(
        token: _asString(_get(j, 'token')) ?? '',
        validFrom: _asDateTime(_get(j, 'validFrom')),
        validTo: _asDateTime(_get(j, 'validTo')),
      );
}

class AuthSession {
  final UserDto user;
  final AuthToken token;
  final bool isGoogleUser;
  final Map<String, dynamic> raw;

  AuthSession({
    required this.user,
    required this.token,
    required this.isGoogleUser,
    required this.raw,
  });
}

/// Endpoints d’authentification + Me.
class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  // --- Register & 2FA ---
  Future<ApiResponse<RegisterResult>> register({
    required String email,
    required String nickName,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/api/v1/Auth/register',
      body: {'email': email.trim(), 'nickName': nickName.trim(), 'password': password},
    );
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final map = res.data ?? <String, dynamic>{};
    final verificationId = _asString(_get(map, 'verificationId'));
    final delivery = _asString(_get(map, 'delivery')) ?? 'email';
    return ApiResponse.ok(
      RegisterResult(
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
      body: {
        'login': login.trim(),
        'password': password,
      },
    );

    if (res.statusCode == 200) {
      return ApiResponse.ok(true, statusCode: res.statusCode);
    }

    String? message = res.message;

    if (res.statusCode == 401 && res.raw is List && (res.raw as List).isNotEmpty) {
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

  Future<ApiResponse<AuthSession>> loginWithGoogle({
    required String idToken,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/google',
      body: {'token': idToken},
    );
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final m = res.data ?? <String, dynamic>{};
    final user = UserDto.fromJson(_get(m, 'user') as Map<String, dynamic>?);
    final token = AuthToken.fromJson(_get(m, 'token') as Map<String, dynamic>?);
    final isGoogleUser = (_get(m, 'isGoogleUser') as bool?) ?? true;

    return ApiResponse.ok(
      AuthSession(user: user, token: token, isGoogleUser: isGoogleUser, raw: m),
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<bool>> passwordForgot({
    required String login,
  }) async {
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
      body: {
        'login': login.trim(),
        'password': password,
        'code': code.trim(),
      },
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

  Future<ApiResponse<AuthSession>> verify2fa({
    required String login,
    required String code,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/2fa/verify',
      body: {'login': login.trim(), 'code': code.trim()},
    );
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final m = res.data ?? <String, dynamic>{};
    final user = UserDto.fromJson(_get(m, 'user') as Map<String, dynamic>?);
    final token = AuthToken.fromJson(_get(m, 'token') as Map<String, dynamic>?);
    final isGoogleUser = (_get(m, 'isGoogleUser') as bool?) ?? false;

    return ApiResponse.ok(
      AuthSession(user: user, token: token, isGoogleUser: isGoogleUser, raw: m),
      statusCode: res.statusCode,
    );
  }

  // --- Me ---
  Future<ApiResponse<UserDto>> me({Map<String, String>? headers}) async {
    final res = await _api.getJson('/api/v1/me', headers: headers);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final m = res.data ?? <String, dynamic>{};
    return ApiResponse.ok(UserDto.fromJson(m), statusCode: res.statusCode);
  }

  Future<ApiResponse<bool>> updateAvatarBase64({
    required String base64,
    Map<String, String>? headers,
  }) async {
    final res = await _api.putJson(
      '/api/v1/me/avatar',
      headers: headers,
      body: {'avatar': base64},
    );
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final success = (res.data?['success'] as bool?) ?? true;
    return success
        ? ApiResponse.ok(true, statusCode: res.statusCode)
        : ApiResponse.err(message: res.data?['message']?.toString());
  }

  Future<ApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
    Map<String, String>? headers,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    };
    final res = await _api.putJson('/api/v1/me/change-password', headers: headers, body: body);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }

  Future<ApiResponse<bool>> deleteMe({Map<String, String>? headers}) async {
    final res = await _api.delete('/api/v1/me', headers: headers);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }
}

// final authApi = AuthApi(apiClient);
AuthApi authApi = AuthApi(apiClient);
