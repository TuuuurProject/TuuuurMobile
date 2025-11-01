import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class RouteHistory extends NavigatorObserver {
  RouteHistory._();
  static final RouteHistory instance = RouteHistory._();

  /// Stack de noms de routes (dernier élément = route actuelle).
  final List<String> _stack = [];

  String? get current => _stack.isEmpty ? null : _stack.last;
  String? get previous => _stack.length >= 2 ? _stack[_stack.length - 2] : null;



  void _push(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    // On veut un vrai historique, donc on **autorise** les doublons
    // (ex: profile -> profile).
    _stack.add(name);
  }

  void _remove(Route<dynamic>? route) {
    // nothing to do
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _push(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute != null) _remove(oldRoute);
    if (newRoute != null) _push(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  /// Retourne vers la page précédente si dispo,
  /// sinon renvoie sur "home".
 void navigateBack(BuildContext context) {
    if (_stack.isNotEmpty) {
      // retirer la route actuelle
      _stack.removeLast();
    }

    if (_stack.isNotEmpty) {
      // nouvelle current = l’ancien prev
      final target = _stack.last;
      context.goNamed(target);
    } else {
      // pile vide -> fallback home
      context.goNamed('home');
    }
  }
}
