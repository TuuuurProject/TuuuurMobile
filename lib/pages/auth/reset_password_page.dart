import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? initialLogin;

  const ResetPasswordPage({super.key, this.initialLogin});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // Controllers
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // UI state
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

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

  void _showToast(String message, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  bool _validateForm() {
    final login = _loginController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (login.isEmpty) {
      _showToast('Le login est requis.');
      return false;
    }
    if (code.isEmpty) {
      _showToast('Le code est requis.');
      return false;
    }
    if (password.isEmpty) {
      _showToast('Le nouveau mot de passe est requis.');
      return false;
    }
    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      _showToast(
        'Mot de passe invalide : min 8, 1 maj, 1 min, 1 chiffre.',
      );
      return false;
    }
    if (password != confirmPassword) {
      _showToast('Les mots de passe ne correspondent pas.');
      return false;
    }
    return true;
  }

  Future<void> _handleResetPassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final res = await authApi.passwordReset(
      login: _loginController.text.trim(),
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res.ok) {
      _showToast('Mot de passe réinitialisé ✅', color: TuuurTheme.brandGreen);
      context.go('/login');
    } else {
      _showToast(res.message ?? 'Réinitialisation impossible.');
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

                  const _FieldLabel('Login'),
                  TextField(
                    controller: _loginController,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('Votre login'),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Code reçu par email'),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('••••••')
                        .copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Nouveau mot de passe'),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration:
                        _buildInputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Confirmer le mot de passe'),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration:
                        _buildInputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured =
                                !_isConfirmPasswordObscured;
                          });
                        },
                      ),
                    ),
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
                        text: _isLoading ? 'Validation...' : 'Valider',
                        onPressed:
                            _isLoading ? null : _handleResetPassword,
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
