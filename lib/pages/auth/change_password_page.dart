import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../auth/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool isObOld = true;
  bool isObNew = true;
  bool isObNew2 = true;
  bool loading = false;

  @override
  void dispose() {
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _toast(String m, {Color color = TuuurTheme.brandOrange}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: color),
    );
  }

  bool _validate() {
    final old = oldCtrl.text;
    final np = newCtrl.text;
    final np2 = confirmCtrl.text;

    if (old.isEmpty || np.isEmpty || np2.isEmpty) {
      _toast('Tous les champs sont requis.');
      return false;
    }
    if (np != np2) {
      _toast('Les mots de passe ne correspondent pas.');
      return false;
    }
    if (np.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(np) ||
        !RegExp(r'[a-z]').hasMatch(np) ||
        !RegExp(r'[0-9]').hasMatch(np)) {
      _toast('Nouveau mot de passe invalide (min 8, 1 maj, 1 min, 1 chiffre).');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final store = MyAuthStore.of(context);
    setState(() => loading = true);
    final res = await authApi.changePassword(
      currentPassword: oldCtrl.text,
      newPassword: newCtrl.text,
      headers: store.authHeaders,
    );
    if (!mounted) return;
    setState(() => loading = false);

    if (res.ok) {
      _toast('Mot de passe mis à jour ✅', color: TuuurTheme.brandGreen);
      context.pop();
    } else {
      _toast(res.message ?? 'Échec de la mise à jour du mot de passe.');
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
                _Labeled('Mot de passe actuel', TextField(
                  controller: oldCtrl,
                  obscureText: isObOld,
                  style: const TextStyle(color: TuuurTheme.brandLightGray),
                  decoration: _input('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObOld ? Icons.visibility : Icons.visibility_off,
                        color: TuuurTheme.brandGray,
                      ),
                      onPressed: () => setState(() => isObOld = !isObOld),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                _Labeled('Nouveau mot de passe', TextField(
                  controller: newCtrl,
                  obscureText: isObNew,
                  style: const TextStyle(color: TuuurTheme.brandLightGray),
                  decoration: _input('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObNew ? Icons.visibility : Icons.visibility_off,
                        color: TuuurTheme.brandGray,
                      ),
                      onPressed: () => setState(() => isObNew = !isObNew),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                _Labeled('Confirmer', TextField(
                  controller: confirmCtrl,
                  obscureText: isObNew2,
                  style: const TextStyle(color: TuuurTheme.brandLightGray),
                  decoration: _input('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObNew2 ? Icons.visibility : Icons.visibility_off,
                        color: TuuurTheme.brandGray,
                      ),
                      onPressed: () => setState(() => isObNew2 = !isObNew2),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GamingButtonSecondary(text: 'Annuler', onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    GamingButtonPrimary(
                      text: loading ? 'Mise à jour…' : 'Valider',
                      onPressed: loading ? null : _submit,
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
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, color: TuuurTheme.brandLightGray, fontSize: 14,
        )),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
