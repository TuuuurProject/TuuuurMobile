import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? initialLogin;
  const ResetPasswordPage({super.key, this.initialLogin});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final loginController = TextEditingController();
  final codeController = TextEditingController();
  final passController = TextEditingController();
  final pass2Controller = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  @override
  void initState() {
    super.initState();
    if ((widget.initialLogin ?? '').isNotEmpty) {
      loginController.text = widget.initialLogin!;
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    codeController.dispose();
    passController.dispose();
    pass2Controller.dispose();
    super.dispose();
  }

  void _toast(String m, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: color),
    );
  }

  bool _validate() {
    final login = loginController.text.trim();
    final code = codeController.text.trim();
    final p1 = passController.text;
    final p2 = pass2Controller.text;

    if (login.isEmpty) {
      _toast('Le login est requis.');
      return false;
    }
    if (code.isEmpty) {
      _toast('Le code est requis.');
      return false;
    }
    if (p1.isEmpty) {
      _toast('Le nouveau mot de passe est requis.');
      return false;
    }
    if (p1.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(p1) ||
        !RegExp(r'[a-z]').hasMatch(p1) ||
        !RegExp(r'[0-9]').hasMatch(p1)) {
      _toast('Mot de passe invalide : min 8, 1 maj, 1 min, 1 chiffre.');
      return false;
    }
    if (p1 != p2) {
      _toast('Les mots de passe ne correspondent pas.');
      return false;
    }
    return true;
  }

  Future<void> _handleReset() async {
    if (!_validate()) return;

    setState(() => isLoading = true);
    final res = await authApi.passwordReset(
      login: loginController.text.trim(),
      code: codeController.text.trim(),
      password: passController.text,
    );
    if (!mounted) return;
    setState(() => isLoading = false);

    if (res.ok) {
      _toast('Mot de passe réinitialisé ✅', color: TuuurTheme.brandGreen);
      context.go('/login');
    } else {
      _toast(res.message ?? 'Réinitialisation impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        RouteHistory.instance.navigateBack(context);
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: AppBar(
          title: const Text('Réinitialiser le mot de passe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goBack(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(32),
              decoration: TuuurStyles.gamingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      FaIcon(FontAwesomeIcons.rotateRight, color: TuuurTheme.brandLightGray, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Saisissez le code et votre nouveau mot de passe',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const _Label('Login'),
                  TextField(
                    controller: loginController,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _input('Votre login'),
                  ),
                  const SizedBox(height: 16),

                  const _Label('Code reçu par email'),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _input('••••••').copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 16),

                  const _Label('Nouveau mot de passe'),
                  TextField(
                    controller: passController,
                    obscureText: obscure1,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _input('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure1 ? Icons.visibility : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () => setState(() => obscure1 = !obscure1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _Label('Confirmer le mot de passe'),
                  TextField(
                    controller: pass2Controller,
                    obscureText: obscure2,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _input('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure2 ? Icons.visibility : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () => setState(() => obscure2 = !obscure2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GamingButtonSecondary(text: 'Annuler', onPressed: () => context.goBack()),
                      const SizedBox(width: 12),
                      GamingButtonPrimary(
                        text: isLoading ? 'Validation...' : 'Valider',
                        onPressed: isLoading ? null : _handleReset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);

  @override
  Widget build(BuildContext context) => Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: TuuurTheme.brandLightGray,
          fontSize: 14,
        ),
      );
}

InputDecoration _input(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: TuuurTheme.brandGray.withOpacity(0.7)),
      filled: true,
      fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: TuuurTheme.brandPurple, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
