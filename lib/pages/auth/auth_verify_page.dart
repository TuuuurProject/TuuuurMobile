import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../stores/auth_store.dart';

class AuthVerifyPage extends StatefulWidget {
  /// Optionnel: pré-remplir le login (pseudo) et/ou un hint d’email.
  final String? initialLogin;
  final String? emailHint;

  const AuthVerifyPage({
    super.key,
    this.initialLogin,
    this.emailHint,
  });

  @override
  State<AuthVerifyPage> createState() => _AuthVerifyPageState();
}

class _AuthVerifyPageState extends State<AuthVerifyPage> {
  // Controllers
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // UI state
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
    super.dispose();
  }

  void _showToast(String msg, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _validateForm() {
    final login = _loginController.text.trim();
    final code = _codeController.text.trim();

    if (login.isEmpty) {
      _showToast('Le pseudo (login) est requis.');
      return false;
    }

    // Codes souvent 6 chiffres, on vérifie strictement pour éviter les erreurs de saisie.
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showToast('Code invalide. Entrez les 6 chiffres reçus par email.');
      return false;
    }

    return true;
  }

  Future<void> handleVerify() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      final res = await authApi.verify2fa(
        login: _loginController.text.trim(),
        code: _codeController.text.trim(),
      );

      if (!mounted) return;

      if (res.ok && res.data != null) {
        final session = res.data!;
        await MyAuthStore.of(context).signInWithSession(session);

        _showToast(
          'Compte vérifié, connexion réussie !',
          color: TuuurTheme.brandGreen,
        );

        context.go('/');
        return;
      }

      _showToast(res.message ?? 'Vérification impossible.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
          title: const Text('Vérifier mon compte'),
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                        'Entrez le code reçu',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: TuuurTheme.brandLightGray,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TuuurTheme.brandPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TuuurTheme.brandPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.emailHint?.isNotEmpty == true
                          ? 'Envoyé à ${widget.emailHint}'
                          : 'Vérification par email',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TuuurTheme.brandLightGray,
                        fontSize: 12,
                      ),
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
                      _LabeledField(
                        label: 'Pseudo (login)',
                        child: TextField(
                          controller: _loginController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration('Votre pseudo'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _LabeledField(
                        label: 'Code à 6 chiffres',
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: _buildInputDecoration('••••••')
                              .copyWith(counterText: ''),
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
                            text: _isLoading
                                ? 'Vérification...'
                                : 'Valider le code',
                            onPressed: _isLoading ? null : handleVerify,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Renvoyer le code (à brancher sur un endpoint backend dédié)
                      TextButton(
                        onPressed: null, // À raccorder à /auth/2fa/resend si disponible
                        child: Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: TuuurTheme.brandPurple.withOpacity(0.7),
                          ),
                        ),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    super.key,
  });

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
