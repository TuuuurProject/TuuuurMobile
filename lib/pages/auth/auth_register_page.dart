import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class AuthRegisterPage extends StatefulWidget {
  final String? returnTo;

  const AuthRegisterPage({super.key, this.returnTo});

  @override
  State<AuthRegisterPage> createState() => _AuthRegisterPageState();
}

class _AuthRegisterPageState extends State<AuthRegisterPage> {
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // API
  final _authApi = ApiModule.instance.authApi;

  // UI state
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Helpers UI

  void _showToast(String msg, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    final nick = _usernameController.text.trim();
    final pass = _passwordController.text;
    final pass2 = _confirmPasswordController.text;

    if (nick.isEmpty) {
      _showToast('Le pseudo est requis.');
      return false;
    }

    if (email.isEmpty) {
      _showToast('L’email est requis.');
      return false;
    }

    if (pass.isEmpty) {
      _showToast('Le mot de passe est requis.');
      return false;
    }

    if (pass != pass2) {
      _showToast('Les mots de passe ne correspondent pas.');
      return false;
    }

    return true;
  }

  // API call

  Future<void> handleRegister() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      final res = await _authApi.register(
        email: _emailController.text.trim(),
        nickName: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (res.ok) {
        _showToast(
          'Un code de vérification vous a été envoyé.',
          color: TuuurTheme.brandGreen,
        );

        context.push(
          '/verify',
          extra: {
            'login': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'returnTo': widget.returnTo ?? '/profile',
          },
        );

        return;
      }

      _showToast(res.message ?? 'Échec de l’inscription.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goBack();
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                          controller: _usernameController,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration(
                            'Choisissez un pseudo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _LabeledField(
                        label: 'Email',
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration('vous@exemple.com'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _LabeledField(
                        label: 'Mot de passe',
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration('••••••••')
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: TuuurTheme.brandGray,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordObscured =
                                          !_isPasswordObscured;
                                    });
                                  },
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm
                      _LabeledField(
                        label: 'Confirmer le mot de passe',
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _isConfirmPasswordObscured,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration('••••••••')
                              .copyWith(
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
                      ),

                      const SizedBox(height: 24),

                      // Actions
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
                            text: _isLoading
                                ? 'Création...'
                                : 'Créer le compte',
                            onPressed: _isLoading ? null : handleRegister,
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
                                horizontal: 12,
                                vertical: 6,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: TuuurTheme.brandPurple.withOpacity(
                                    0.3,
                                  ),
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
  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: TuuurTheme.brandGray.withOpacity(0.7)),
    filled: true,
    fillColor: TuuurTheme.brandDarkGray.withOpacity(0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: TuuurTheme.brandPurple, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: TuuurTheme.brandPurple.withOpacity(0.3)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

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
