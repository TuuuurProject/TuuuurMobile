import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';
import '../../navigation/route_history.dart';
import '../../api/auth_api_service.dart';

class AuthRegisterPage extends StatefulWidget {
  const AuthRegisterPage({super.key});

  @override
  State<AuthRegisterPage> createState() => _AuthRegisterPageState();
}

class _AuthRegisterPageState extends State<AuthRegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _auth = authApi;

  bool isObscure1 = true;
  bool isObscure2 = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ---- Helpers UI -----------------------------------------------------------

  void _toast(String msg, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _clientValidate() {
    final email = emailController.text.trim();
    final nick = usernameController.text.trim();
    final pass = passwordController.text;
    final pass2 = confirmPasswordController.text;

    if (nick.isEmpty) {
      _toast('Le pseudo est requis.');
      return false;
    }

    if (email.isEmpty) {
      _toast('L’email est requis.');
      return false;
    }

    if (pass.isEmpty) {
      _toast('Le mot de passe est requis.');
      return false;
    }
   
    if (pass != pass2) {
      _toast('Les mots de passe ne correspondent pas.');
      return false;
    }

    return true;
  }

  // ---- API call -------------------------------------------------------------

  Future<void> handleRegister() async {
  if (!_clientValidate()) return;

  setState(() => isLoading = true);
  try {
    final res = await _auth.register(
      email: emailController.text.trim(),
      nickName: usernameController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (res.ok) {
      _toast('Un code de vérification vous a été envoyé.',
          color: TuuurTheme.brandGreen);

      context.push('/verify', extra: {
        'login': usernameController.text.trim(),
        'email': emailController.text.trim(),
      });

      return;
    }

    _toast(res.message ?? 'Échec de l’inscription.');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: AppBar(
          title: const Text('Créer un compte'),
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.userPlus,
                        color: TuuurTheme.brandLightGray,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandLightGray,
                        ),
                      ),
                    ],
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
                    _LabeledField(
                      label: 'Pseudo',
                      child: TextField(
                        controller: usernameController,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: _input('Choisissez un pseudo'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _LabeledField(
                      label: 'Email',
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: _input('vous@exemple.com'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    _LabeledField(
                      label: 'Mot de passe',
                      child: TextField(
                        controller: passwordController,
                        obscureText: isObscure1,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: _input('••••••••').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscure1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: TuuurTheme.brandGray,
                            ),
                            onPressed: () =>
                                setState(() => isObscure1 = !isObscure1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm
                    _LabeledField(
                      label: 'Confirmer le mot de passe',
                      child: TextField(
                        controller: confirmPasswordController,
                        obscureText: isObscure2,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: _input('••••••••').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscure2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: TuuurTheme.brandGray,
                            ),
                            onPressed: () =>
                                setState(() => isObscure2 = !isObscure2),
                          ),
                        ),
                      ),
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
                          text: isLoading ? 'Création...' : 'Créer le compte',
                          onPressed: isLoading ? null : handleRegister,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Lien login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Déjà inscrit ?',
                          style: TextStyle(
                            color: TuuurTheme.brandGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push('/login'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    TuuurTheme.brandPurple.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: TuuurTheme.brandLightGray,
                              fontSize: 12,
                            ),
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

  // Style d’input factorisé
  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: TuuurTheme.brandGray.withOpacity(0.7)),
        filled: true,
        fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: TuuurTheme.brandPurple.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TuuurTheme.brandPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: TuuurTheme.brandPurple.withOpacity(0.3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: TuuurTheme.brandLightGray,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
