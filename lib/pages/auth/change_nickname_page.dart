import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api_service.dart';
import '../../stores/auth_store.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import 'auth_shared.dart';

class ChangeNicknamePage extends StatefulWidget {
  final String? initialNickname;

  const ChangeNicknamePage({super.key, this.initialNickname});

  @override
  State<ChangeNicknamePage> createState() => _ChangeNicknamePageState();
}

class _ChangeNicknamePageState extends State<ChangeNicknamePage> {
  late final TextEditingController _nickController =
      TextEditingController(text: widget.initialNickname ?? '');

  bool _isLoading = false;

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = MyAuthStore.of(context);
    setState(() => _isLoading = true);

    final res = await authApi.updateNickname(
      nickname: _nickController.text,
      headers: store.authHeaders,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.ok) {
      await store.updateUser(res.data!);

      if (!mounted) return;
      AuthSnackbars.show('Pseudo mis à jour ✅', color: TuuurTheme.brandGreen);
      context.pop(_nickController.text);
    } else {
      AuthSnackbars.show(res.message ?? 'Échec de la mise à jour du pseudo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuuurTheme.brandDark,
      appBar: AppBar(
        title: const Text('Changer le pseudo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop<String?>(null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AuthCard(
          maxWidth: 500,
          child: Column(
            children: [
              TextField(
                controller: _nickController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _submit(),
                style: const TextStyle(color: TuuurTheme.brandLightGray),
                decoration: InputDecoration(
                  labelText: 'Nouveau pseudo',
                  labelStyle: const TextStyle(color: TuuurTheme.brandGray),
                  filled: true,
                  fillColor: TuuurTheme.brandDarkGray.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TuuurTheme.brandPurple.withOpacity(0.4),
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
                    onPressed: () => context.pop<String?>(null),
                  ),
                  const SizedBox(width: 12),
                  GamingButtonPrimary(
                    text: _isLoading ? 'Mise à jour…' : 'Valider',
                    onPressed: _isLoading ? null : _submit,
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
