import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/auth/auth_models.dart';

/// Stocke user + token en mémoire et dans le secure storage.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const String _tokenStorageKey = 'auth.token';
  static const String _userStorageKey = 'auth.user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserDto? _user;
  AuthTokenDto? _token;

  UserDto? get user => _user;
  AuthTokenDto? get token => _token;
  bool get isAuthenticated => (_token?.token.isNotEmpty ?? false);
  bool get isGuest =>
      isAuthenticated && (_user?.email == null || _user!.email!.isEmpty);

  /// À appeler au démarrage (hydrate depuis le secure storage).
  Future<void> load() async {
    final tokenRaw = await _storage.read(key: _tokenStorageKey);
    final userRaw = await _storage.read(key: _userStorageKey);

    if (tokenRaw != null && tokenRaw.isNotEmpty) {
      final map = jsonDecode(tokenRaw) as Map<String, dynamic>;
      _token = AuthTokenDto.fromJson(map);
    }

    if (userRaw != null && userRaw.isNotEmpty) {
      final map = jsonDecode(userRaw) as Map<String, dynamic>;
      _user = UserDto.fromJson(map);
    }

    notifyListeners();
  }

  /// Persiste une session issue de /auth/2fa/verify.
  Future<void> signInWithSession(AuthSessionDto session) async {
    _user = session.user;
    _token = session.token;

    await _storage.write(
      key: _tokenStorageKey,
      value: jsonEncode(_token?.toJson() ?? {}),
    );

    await _storage.write(
      key: _userStorageKey,
      value: jsonEncode(_user?.toJson() ?? {}),
    );

    notifyListeners();
  }

  /// Supprime tout (déconnexion).
  Future<void> signOut() async {
    _user = null;
    _token = null;

    await _storage.delete(key: _tokenStorageKey);
    await _storage.delete(key: _userStorageKey);

    notifyListeners();
  }

  Future<void> updateUser(UserDto user) async {
    _user = user;

    await _storage.write(
      key: _userStorageKey,
      value: jsonEncode({
        'id': _user?.id,
        'nickName': _user?.nickName,
        'email': _user?.email,
        'avatar': _user?.avatar,
        'isAdmin': _user?.isAdmin,
        'isNew': _user?.isNew,
      }),
    );

    notifyListeners();
  }

  /// Entêtes utiles pour des appels authentifiés.
  Map<String, String> get authHeaders {
    final t = _token?.token;
    if (t == null || t.isEmpty) return const {};
    return {'Authorization': 'Bearer $t'};
  }
}

/// InheritedNotifier pour exposer le store dans le tree.
class MyAuthStore extends InheritedNotifier<AuthStore> {
  const MyAuthStore({
    super.key,
    required AuthStore super.notifier,
    required super.child,
  });

  static AuthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MyAuthStore>();
    assert(scope != null, 'MyAuthStore non trouvé dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  @override
  bool updateShouldNotify(covariant InheritedNotifier<AuthStore> oldWidget) {
    return oldWidget.notifier != notifier;
  }
}
