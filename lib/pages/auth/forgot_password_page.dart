import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../navigation/route_history.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final loginController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    loginController.dispose();
    super.dispose();
  }

  void _toast(String m, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: color),
    );
  }

  bool _clientValidate() {
    final login = loginController.text.trim();
    if (login.isEmpty) {
      _toast('Le login est requis.');
      return false;
    }
    return true;
  }

  Future<void> _handleForgot() async {
    if (!_clientValidate()) return;

    setState(() => isLoading = true);
    final res = await authApi.passwordForgot(login: loginController.text.trim());
    if (!mounted) return;
    setState(() => isLoading = false);

    if (res.ok) {
      _toast('Code envoyé par email. Consultez votre boîte 📬', color: TuuurTheme.brandGreen);
      context.push(
        '/reset-password',
        extra: {'login': loginController.text.trim()},
      );
    } else {
      _toast(res.message ?? 'Impossible de démarrer la procédure.');
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
                      FaIcon(FontAwesomeIcons.key, color: TuuurTheme.brandLightGray, size: 22),
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
                    style: TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const _Label('Login'),
                  TextField(
                    controller: loginController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _input('Votre login'),
                    onSubmitted: (_) => isLoading ? null : _handleForgot(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GamingButtonSecondary(text: 'Annuler', onPressed: () => context.goBack()),
                      const SizedBox(width: 12),
                      GamingButtonPrimary(
                        text: isLoading ? 'Envoi...' : 'Envoyer le code',
                        onPressed: isLoading ? null : _handleForgot,
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
