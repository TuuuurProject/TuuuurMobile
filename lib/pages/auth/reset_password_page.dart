import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'auth_shared.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? initialLogin;
  final AuthApi? authApiOverride;
  final String? returnTo;

  const ResetPasswordPage({super.key, this.initialLogin, this.authApiOverride, this.returnTo});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  AuthApi get _authApi => widget.authApiOverride ?? ApiModule.instance.authApi;

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initialLogin = widget.initialLogin;
    if (initialLogin != null && initialLogin.isNotEmpty) {
      _loginController.text = initialLogin;
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final login = _loginController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (login.isEmpty) {
      AuthSnackbars.show('Le login est requis.');
      return false;
    }
    if (code.isEmpty) {
      AuthSnackbars.show('Le code est requis.');
      return false;
    }
    if (password.isEmpty) {
      AuthSnackbars.show('Le nouveau mot de passe est requis.');
      return false;
    }
    if (!AuthValidators.isValidPassword(password)) {
      AuthSnackbars.show(
        'Mot de passe invalide : min 8, 1 maj, 1 min, 1 chiffre.',
      );
      return false;
    }
    if (password != confirmPassword) {
      AuthSnackbars.show('Les mots de passe ne correspondent pas.');
      return false;
    }
    return true;
  }

  Future<void> _handleResetPassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final res = await _authApi.passwordReset(
      login: _loginController.text.trim(),
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.ok) {
      AuthSnackbars.show(
        'Mot de passe réinitialisé ✅',
        color: TuuurTheme.brandGreen,
      );
      if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
        context.push('/login', extra: {'returnTo': widget.returnTo});
      } else {
        context.go('/login');
      }
    } else {
      AuthSnackbars.show(res.message ?? 'Réinitialisation impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Réinitialiser le mot de passe',
      cardMaxWidth: 560,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: TuuurTheme.brandLightGray,
                  size: 20,
                ),
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

            AuthLabeledField(
              label: 'Login',
              child: TextField(
                controller: _loginController,
                style: const TextStyle(color: TuuurTheme.brandLightGray),
                decoration: authInputDecoration('Votre login'),
              ),
            ),
            const SizedBox(height: 16),

            AuthLabeledField(
              label: 'Code reçu par email',
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: TuuurTheme.brandLightGray),
                decoration: authInputDecoration(
                  '••••••',
                ).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(height: 16),

            AuthPasswordField(
              controller: _passwordController,
              label: 'Nouveau mot de passe',
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            AuthPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              enabled: !_isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _handleResetPassword();
              },
            ),
            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 12,
              children: [
                GamingButtonSecondary(
                  text: 'Annuler',
                  onPressed: () => context.goBack(),
                ),
                GamingButtonPrimary(
                  text: _isLoading ? 'Validation...' : 'Valider',
                  onPressed: _isLoading ? null : _handleResetPassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
