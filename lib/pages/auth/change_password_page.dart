import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_module.dart';
import '../../api/auth/auth_api_service.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'auth_shared.dart';

class ChangePasswordPage extends StatefulWidget {
  final AuthApi? authApiOverride;

  const ChangePasswordPage({super.key, this.authApiOverride});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  AuthApi get _authApi => widget.authApiOverride ?? ApiModule.instance.authApi;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final currentPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      AuthSnackbars.show('Tous les champs sont requis.');
      return false;
    }

    if (newPassword != confirmPassword) {
      AuthSnackbars.show('Les mots de passe ne correspondent pas.');
      return false;
    }

    if (!AuthValidators.isValidPassword(newPassword)) {
      AuthSnackbars.show(
        'Nouveau mot de passe invalide (min 8, 1 maj, 1 min, 1 chiffre).',
      );
      return false;
    }

    return true;
  }

  Future<void> _handleChangePassword() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final res = await _authApi.changePassword(
      currentPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.ok) {
      AuthSnackbars.show(
        'Mot de passe mis à jour ✅',
        color: TuuurTheme.brandGreen,
      );
      context.pop();
    } else {
      AuthSnackbars.show(
        res.message ?? 'Échec de la mise à jour du mot de passe.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuuurTheme.brandDark,
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AuthCard(
          maxWidth: 500,
          child: Column(
            children: [
              AuthPasswordField(
                controller: _oldPasswordController,
                label: 'Mot de passe actuel',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              AuthPasswordField(
                controller: _newPasswordController,
                label: 'Nouveau mot de passe',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              AuthPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmer',
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) _handleChangePassword();
                },
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GamingButtonSecondary(
                    text: 'Annuler',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  GamingButtonPrimary(
                    text: _isLoading ? 'Mise à jour…' : 'Valider',
                    onPressed: _isLoading ? null : _handleChangePassword,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
