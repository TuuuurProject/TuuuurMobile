import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'auth_shared.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _loginController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final login = _loginController.text.trim();
    if (login.isEmpty) {
      AuthSnackbars.show('Le login est requis.');
      return false;
    }
    return true;
  }

  Future<void> _handleForgotPassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    final login = _loginController.text.trim();

    final res = await authApi.passwordForgot(login: login);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.ok) {
      AuthSnackbars.show(
        'Code envoyé par email. Consultez votre boîte 📬',
        color: TuuurTheme.brandGreen,
      );
      context.push('/reset-password', extra: {'login': login});
    } else {
      AuthSnackbars.show(res.message ?? 'Impossible de démarrer la procédure.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Mot de passe oublié',
      cardMaxWidth: 500,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.key,
                color: TuuurTheme.brandLightGray,
                size: 22,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Recevoir un code de réinitialisation',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TuuurTheme.brandLightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Indiquez votre login. Nous vous enverrons un code pour réinitialiser votre mot de passe.',
            style: TextStyle(
              color: TuuurTheme.brandGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          AuthLabeledField(
            label: 'Login',
            child: TextField(
              controller: _loginController,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: TuuurTheme.brandLightGray),
              decoration: authInputDecoration('Votre login'),
              onSubmitted: (_) {
                if (!_isLoading) _handleForgotPassword();
              },
            ),
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
                text: _isLoading ? 'Envoi...' : 'Envoyer le code',
                onPressed: _isLoading ? null : _handleForgotPassword,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
