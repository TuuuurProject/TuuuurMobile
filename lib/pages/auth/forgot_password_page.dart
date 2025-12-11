import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controllers
  final TextEditingController _loginController = TextEditingController();

  // UI state
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  void _showToast(String message, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  bool _validateForm() {
    final login = _loginController.text.trim();
    if (login.isEmpty) {
      _showToast('Le login est requis.');
      return false;
    }
    return true;
  }

  Future<void> _handleForgotPassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    final res =
        await authApi.passwordForgot(login: _loginController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res.ok) {
      _showToast(
        'Code envoyé par email. Consultez votre boîte 📬',
        color: TuuurTheme.brandGreen,
      );
      context.push(
        '/reset-password',
        extra: {'login': _loginController.text.trim()},
      );
    } else {
      _showToast(res.message ?? 'Impossible de démarrer la procédure.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.goBack();
      },
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: AppBar(
          title: const Text('Mot de passe oublié'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goBack(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: TuuurStyles.gamingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
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
                  const _FieldLabel('Login'),
                  TextField(
                    controller: _loginController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('Votre login'),
                    onSubmitted: (_) =>
                        _isLoading ? null : _handleForgotPassword(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GamingButtonSecondary(
                        text: 'Annuler',
                        onPressed: () => context.goBack(),
                      ),
                      const SizedBox(width: 12),
                      GamingButtonPrimary(
                        text: _isLoading ? 'Envoi...' : 'Envoyer le code',
                        onPressed:
                            _isLoading ? null : _handleForgotPassword,
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

  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: TuuurTheme.brandGray.withOpacity(0.7),
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
          borderSide: BorderSide(
            color: TuuurTheme.brandPurple,
            width: 2,
          ),
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: TuuurTheme.brandLightGray,
        fontSize: 14,
      ),
    );
  }
}
