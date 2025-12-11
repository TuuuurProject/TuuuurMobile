import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // UI state
  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
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
    final currentPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showToast('Tous les champs sont requis.');
      return false;
    }

    if (newPassword != confirmPassword) {
      _showToast('Les mots de passe ne correspondent pas.');
      return false;
    }

    if (newPassword.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(newPassword) ||
        !RegExp(r'[a-z]').hasMatch(newPassword) ||
        !RegExp(r'[0-9]').hasMatch(newPassword)) {
      _showToast(
        'Nouveau mot de passe invalide (min 8, 1 maj, 1 min, 1 chiffre).',
      );
      return false;
    }

    return true;
  }

  Future<void> _handleChangePassword() async {
    if (!_validateForm()) return;

    final store = MyAuthStore.of(context);

    setState(() => _isLoading = true);

    final res = await authApi.changePassword(
      currentPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      headers: store.authHeaders,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res.ok) {
      _showToast('Mot de passe mis à jour ✅', color: TuuurTheme.brandGreen);
      context.pop();
    } else {
      _showToast(res.message ?? 'Échec de la mise à jour du mot de passe.');
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
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: TuuurStyles.gamingCard,
            child: Column(
              children: [
                _LabeledField(
                  label: 'Mot de passe actuel',
                  child: TextField(
                    controller: _oldPasswordController,
                    obscureText: _isOldPasswordObscured,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOldPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _isOldPasswordObscured = !_isOldPasswordObscured;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Nouveau mot de passe',
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: _isNewPasswordObscured,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: TuuurTheme.brandGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordObscured = !_isNewPasswordObscured;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Confirmer',
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    style: const TextStyle(color: TuuurTheme.brandLightGray),
                    decoration: _buildInputDecoration('••••••••').copyWith(
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
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
