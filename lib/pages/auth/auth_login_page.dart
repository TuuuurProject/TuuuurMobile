import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';
import '../../navigation/route_history.dart';
import '../../api/auth_api_service.dart';
import '../auth/auth_store.dart';

const kGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

class AuthLoginPage extends StatefulWidget {
  const AuthLoginPage({super.key});

  @override
  State<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends State<AuthLoginPage> {
  final pseudoController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObscure = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    pseudoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _toast(String msg, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _clientValidate() {
    final pseudo = pseudoController.text.trim();
    final pass = passwordController.text;
    if (pseudo.isEmpty) {
      _toast('Le pseudo est requis.');
      return false;
    }
    if (pass.isEmpty) {
      _toast('Le mot de passe est requis.');
      return false;
    }
    return true;
  }

  Future<void> handleLogin() async {
    if (!_clientValidate()) return;

    setState(() => isLoading = true);
    try {
      final login = pseudoController.text.trim();
      final password = passwordController.text;

      final res = await authApi.login(login: login, password: password);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (!res.ok) {
        _toast(res.message ?? 'Connexion impossible.');
        return;
      }

      // 200 => code envoyé -> on redirige vers la page de vérification
      _toast('Code envoyé par email. Vérifiez votre boîte 📬', color: TuuurTheme.brandCyan);
      context.push('/verify', extra: {'login': login});
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast('Erreur : $e');
    }
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isGoogleLoading = true);
    try {
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: kGoogleWebClientId,
      );

      final account = await google.signIn();
      if (account == null) {
        setState(() => isGoogleLoading = false);
        return; // annulé
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('idToken introuvable. Vérifie le serverClientId (Web Client ID) / config OAuth.');
      }

      final res = await authApi.loginWithGoogle(idToken: idToken);
      setState(() => isGoogleLoading = false);

      if (!res.ok || res.data == null) {
        _toast(res.message ?? 'Connexion Google refusée.');
        return;
      }

      final session = res.data!;
      await MyAuthStore.of(context).signInWithSession(session);

      _toast('Connecté avec Google ✅', color: TuuurTheme.brandGreen);
      context.go('/');
    } catch (e) {
      setState(() => isGoogleLoading = false);
      _toast('Erreur Google: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // déjà géré
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: AppBar(
          title: const Text('Connexion'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goBack(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Header: Wrap pour éviter tout overflow
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.lock,
                        color: TuuurTheme.brandLightGray,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandLightGray,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TuuurTheme.brandCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TuuurTheme.brandCyan.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Pseudo + mot de passe',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32),
                  decoration: TuuurStyles.gamingCard,
                  child: Column(
                    children: [
                      // Pseudo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pseudo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: pseudoController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: TuuurTheme.brandLightGray),
                            decoration: InputDecoration(
                              hintText: 'Votre pseudo',
                              hintStyle: TextStyle(color: TuuurTheme.brandGray.withOpacity(0.7)),
                              filled: true,
                              fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide(color: TuuurTheme.brandPurple, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Mot de passe
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mot de passe',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: passwordController,
                            obscureText: isObscure,
                            style: const TextStyle(color: TuuurTheme.brandLightGray),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: TuuurTheme.brandGray.withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isObscure ? Icons.visibility : Icons.visibility_off,
                                  color: TuuurTheme.brandGray,
                                ),
                                onPressed: () => setState(() => isObscure = !isObscure),
                              ),
                              filled: true,
                              fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide(color: TuuurTheme.brandPurple, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
                                ),
                              ),
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GamingButtonSecondary(
                            text: 'Annuler',
                            onPressed: () => context.goBack(),
                          ),
                          const SizedBox(width: 12),
                          GamingButtonPrimary(
                            text: isLoading ? 'Connexion...' : 'Se connecter',
                            onPressed: isLoading ? null : handleLogin,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- Séparateur ---
                      Row(
                        children: const [
                          Expanded(child: Divider(color: TuuurTheme.brandGray)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('ou',
                                style: TextStyle(color: TuuurTheme.brandGray, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: TuuurTheme.brandGray)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bouton Google
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isGoogleLoading ? null : handleGoogleLogin,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 16, color: Colors.white),
                          label: Text(
                            isGoogleLoading ? 'Connexion Google...' : 'Continuer avec Google',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: const Color(0xFF4285F4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Lien register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pas de compte ?',
                              style: TextStyle(color: TuuurTheme.brandGray, fontSize: 14)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
                              ),
                            ),
                            child: const Text(
                              'Créer un compte',
                              style: TextStyle(color: TuuurTheme.brandLightGray, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
