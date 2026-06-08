import '../api_helpers.dart';

/// Registration result (2FA expected).
class RegisterResultDto {
  final bool verificationRequired;
  final String? verificationId;
  final String delivery; // 'email'/'sms'
  final Map<String, dynamic> raw;
  const RegisterResultDto({
    required this.verificationRequired,
    required this.delivery,
    required this.raw,
    this.verificationId,
  });
}

class LoginResultDto {
  final bool requires2fa;
  final AuthSessionDto? session;
  final String? delivery;
  final String? emailHint;
  const LoginResultDto({
    required this.requires2fa,
    this.session,
    this.delivery,
    this.emailHint,
  });
}

/// Session / user models.
class UserDto {
  final String? id;
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
      id: asString(get(j, 'id')),
      nickName: asString(get(j, 'nickName')),
      email: asString(get(j, 'email')),
      avatar: asString(get(j, 'avatar')),
      isAdmin: asBool(get(j, 'isAdmin')),
      isNew: asBool(get(j, 'isNew')),
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

class AuthTokenDto {
  final String token;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  AuthTokenDto({
    required this.token,
    this.validFrom,
    this.validTo,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  factory AuthTokenDto.fromJson(Map<String, dynamic>? j) => AuthTokenDto(
    token: asString(get(j, 'token')) ?? '',
    validFrom: asDateTime(get(j, 'validFrom')),
    validTo: asDateTime(get(j, 'validTo')),
    refreshToken: asString(get(j, 'refreshToken')),
    refreshTokenExpiresAt: asDateTime(get(j, 'refreshTokenExpiresAt')),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'validFrom': validFrom?.toUtc().toIso8601String(),
    'validTo': validTo?.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt?.toUtc().toIso8601String(),
  };
}

class AuthSessionDto {
  final UserDto user;
  final AuthTokenDto token;
  final bool isGoogleUser;
  final Map<String, dynamic> raw;

  AuthSessionDto({
    required this.user,
    required this.token,
    required this.isGoogleUser,
    required this.raw,
  });
}
