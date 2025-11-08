import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';
import 'auth_store.dart';


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
  final loginController = TextEditingController();
  final codeController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLogin != null && widget.initialLogin!.isNotEmpty) {
      loginController.text = widget.initialLogin!;
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _toast(String msg, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _clientValidate() {
    final login = loginController.text.trim();
    final code = codeController.text.trim();

    if (login.isEmpty) {
      _toast('Le pseudo (login) est requis.');
      return false;
    }
    // Codes souvent 6 chiffres, on vérifie strictement pour éviter les erreurs de saisie.
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _toast('Code invalide. Entrez les 6 chiffres reçus par email.');
      return false;
    }
    return true;
  }

  Future<void> handleVerify() async {
    if (!_clientValidate()) return;

    setState(() => isLoading = true);
    try {
      final res = await authApi.verify2fa(
        login: loginController.text.trim(),
        code: codeController.text.trim(),
      );

      if (!mounted) return;

      if (res.ok && res.data != null) {
        final session = res.data!;
        await MyAuthStore.of(context).signInWithSession(session);

        _toast('Compte vérifié, connexion réussie !', color: TuuurTheme.brandGreen);

        context.go('/');
        return;
      }

      _toast(res.message ?? 'Vérification impossible.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          controller: loginController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: TuuurTheme.brandLightGray),
                          decoration: _input('Votre pseudo'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _LabeledField(
                        label: 'Code à 6 chiffres',
                        child: TextField(
                          controller: codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: TuuurTheme.brandLightGray),
                          decoration: _input('••••••').copyWith(counterText: ''),
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
                            text: isLoading ? 'Vérification...' : 'Valider le code',
                            onPressed: isLoading ? null : handleVerify,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Renvoyer: dépend d’un endpoint backend spécifique (non fourni ici).
                      TextButton(
                        onPressed: null, // TODO: brancher sur /auth/2fa/resend si présent
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
