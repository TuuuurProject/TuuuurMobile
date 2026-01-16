import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../api/auth_api_service.dart';
import '../../navigation/app_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../stores/auth_store.dart';
import 'auth_shared.dart';

class AuthVerifyPage extends StatefulWidget {
  final String? initialLogin;
  final String? emailHint;
  final String? returnTo;
  final AuthApi? authApi;

  const AuthVerifyPage({
    super.key,
    this.initialLogin,
    this.emailHint,
    this.returnTo,
    this.authApi,
  });

  @override
  State<AuthVerifyPage> createState() => _AuthVerifyPageState();
}

class _AuthVerifyPageState extends State<AuthVerifyPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  AuthApi get _authApi => widget.authApi ?? ApiModule.instance.authApi;

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

  bool _validateForm() {
    final login = _loginController.text.trim();
    final code = _codeController.text.trim();

    if (login.isEmpty) {
      AuthSnackbars.show('Le pseudo (login) est requis.');
      return false;
    }

    if (!AuthValidators.isSixDigitCode(code)) {
      AuthSnackbars.show('Code invalide. Entrez les 6 chiffres reçus par email.');
      return false;
    }

    return true;
  }

  Future<void> handleVerify() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      final res = await _authApi.verify2fa(
        login: _loginController.text.trim(),
        code: _codeController.text.trim(),
      );

      if (!mounted) return;

      if (res.ok && res.data != null) {
        final session = res.data!;

        final router = GoRouter.of(context);
        final returnTo = widget.returnTo;

        await MyAuthStore.of(context).signInWithSession(session);
        if (!mounted) return;

        AuthSnackbars.show(
          'Compte vérifié, connexion réussie !',
          color: TuuurTheme.brandGreen,
        );

        if (returnTo != null && returnTo.isNotEmpty) {
          router.go(returnTo);
        } else if (router.canPop()) {
          router.pop();
        } else {
          router.go('/');
        }
        return;
      }

      AuthSnackbars.show(res.message ?? 'Vérification impossible.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPopScope(
      onBack: () => context.goBack(),
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
                      color: TuuurTheme.brandPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TuuurTheme.brandPurple.withValues(alpha: 0.3),
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

              AuthCard(
                maxWidth: 500,
                child: Column(
                  children: [
                    AuthLabeledField(
                      label: 'Pseudo (login)',
                      child: TextField(
                        controller: _loginController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: authInputDecoration('Votre pseudo'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    AuthLabeledField(
                      label: 'Code à 6 chiffres',
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(color: TuuurTheme.brandLightGray),
                        decoration: authInputDecoration('••••••').copyWith(counterText: ''),
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
                          text: _isLoading ? 'Vérification...' : 'Valider le code',
                          onPressed: _isLoading ? null : handleVerify,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: null,
                      child: Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          color: TuuurTheme.brandPurple.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
