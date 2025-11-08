import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/auth_api_service.dart';

/// Stocke user + token en mémoire et dans le secure storage.
class AuthStore extends ChangeNotifier {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final _storage = const FlutterSecureStorage();
  static const _kTokenKey = 'auth.token';
  static const _kUserKey = 'auth.user';

  UserDto? _user;
  AuthToken? _token;

  UserDto? get user => _user;
  AuthToken? get token => _token;
  bool get isAuthenticated => (_token?.token.isNotEmpty ?? false);

  /// À appeler au démarrage (hydrate depuis le secure storage).
  Future<void> load() async {
    final tokenRaw = await _storage.read(key: _kTokenKey);
    final userRaw = await _storage.read(key: _kUserKey);

    if (tokenRaw != null && tokenRaw.isNotEmpty) {
      final map = jsonDecode(tokenRaw) as Map<String, dynamic>;
      _token = AuthToken.fromJson(map);
    }
    if (userRaw != null && userRaw.isNotEmpty) {
      final map = jsonDecode(userRaw) as Map<String, dynamic>;
      _user = UserDto.fromJson(map);
    }
    notifyListeners();
  }

  /// Persiste une session issue de /auth/2fa/verify.
  Future<void> signInWithSession(AuthSession session) async {
    _user = session.user;
    _token = session.token;

    await _storage.write(
      key: _kTokenKey,
      value: jsonEncode({
        'token': _token?.token ?? '',
        'validFrom': _token?.validFrom?.toIso8601String(),
        'validTo': _token?.validTo?.toIso8601String(),
      }),
    );

    await _storage.write(
      key: _kUserKey,
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

  /// Supprime tout (déconnexion).
  Future<void> signOut() async {
    _user = null;
    _token = null;
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUserKey);
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
    required AuthStore notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AuthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MyAuthStore>();
    assert(scope != null, 'MyAuthStore non trouvé dans l’arbre de widgets.');
    return scope!.notifier!;
  }

  @override
  bool updateShouldNotify(covariant InheritedNotifier<AuthStore> oldWidget) {
    return oldWidget.notifier != notifier;
  }
}
