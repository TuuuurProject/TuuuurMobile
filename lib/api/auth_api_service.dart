import 'api_client.dart';
import 'api_helpers.dart';

dynamic _get(Map<String, dynamic>? j, String key) => get(j, key);
String? _asString(dynamic v) => asString(v);
int? _asInt(dynamic v) => asInt(v);
bool? _asBool(dynamic v) => asBool(v);
DateTime? _asDateTime(dynamic v) => asDateTime(v);

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
  final String? delivery;
  final String? emailHint;
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
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  AuthToken({
    required this.token,
    this.validFrom,
    this.validTo,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic>? j) => AuthToken(
        token: _asString(_get(j, 'token')) ?? '',
        validFrom: _asDateTime(_get(j, 'validFrom')),
        validTo: _asDateTime(_get(j, 'validTo')),
        refreshToken: _asString(_get(j, 'refreshToken')),
        refreshTokenExpiresAt: _asDateTime(_get(j, 'refreshTokenExpiresAt')),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'validFrom': validFrom?.toUtc().toIso8601String(),
        'validTo': validTo?.toUtc().toIso8601String(),
        'refreshToken': refreshToken,
        'refreshTokenExpiresAt': refreshTokenExpiresAt?.toUtc().toIso8601String(),
      };
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

  ApiResponse<AuthSession> _buildAuthSession(Map<String, dynamic> m, int? statusCode, {bool defaultIsGoogleUser = false}) {
    final userData = _get(m, 'user');
    final tokenData = _get(m, 'token');
    
    final user = UserDto.fromJson(userData is Map ? Map<String, dynamic>.from(userData) : null);
    final token = AuthToken.fromJson(tokenData is Map ? Map<String, dynamic>.from(tokenData) : null);
    final isGoogleUser = (_get(m, 'isGoogleUser') as bool?) ?? defaultIsGoogleUser;

    return ApiResponse.ok(
      AuthSession(user: user, token: token, isGoogleUser: isGoogleUser, raw: m),
      statusCode: statusCode,
    );
  }
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
    return _buildAuthSession(m, res.statusCode, defaultIsGoogleUser: true);
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
    return _buildAuthSession(m, res.statusCode);
  }

  /// Refresh le token d'authentification.
  Future<ApiResponse<AuthSession>> refreshToken({
    required String bearer,
    required String refreshToken,
  }) async {
    final res = await _api.postJson(
      '/api/v1/auth/refresh',
      body: {
        'bearer': bearer,
        'refreshToken': refreshToken,
      },
    );
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final m = res.data ?? <String, dynamic>{};
    return _buildAuthSession(m, res.statusCode);
  }

  // --- Me ---
  /// Récupère les informations de l'utilisateur connecté.
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
  Future<ApiResponse<UserDto>> me() async {
    final res = await _api.getJson('/api/v1/me', auth: true);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    final m = res.data ?? <String, dynamic>{};
    return ApiResponse.ok(UserDto.fromJson(m), statusCode: res.statusCode);
  }

  /// Mise à jour de l'avatar en base64.
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
  Future<ApiResponse<bool>> updateAvatarBase64({
    required String base64,
  }) async {
    final res = await _api.putJson(
      '/api/v1/me/avatar',
      auth: true,
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

  /// Change le mot de passe de l'utilisateur.
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
  Future<ApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    };
    final res = await _api.putJson('/api/v1/me/change-password', auth: true, body: body);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }

  /// Supprime le compte utilisateur.
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
  Future<ApiResponse<bool>> deleteMe() async {
    final res = await _api.delete('/api/v1/me', auth: true);
    if (!res.ok) {
      return ApiResponse.err(message: res.message, statusCode: res.statusCode, raw: res.raw);
    }
    return ApiResponse.ok(true, statusCode: res.statusCode);
  }

  /// Met à jour le pseudo de l'utilisateur.
  /// ATTENTION: cette méthode nécessite l'authentification automatique via ApiClient.
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
