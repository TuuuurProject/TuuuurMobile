import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/api_module.dart';
import '../../api/auth/auth_api_service.dart';
import '../../api/group/group_api_service.dart';
import '../../stores/auth_store.dart';
import '../../stores/group_coordinator.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class GroupJoinPage extends StatefulWidget {
  final VoidCallback onBack;

  final void Function({required String partyId, required String code}) onJoined;

  final GroupApi? groupApiOverride;
  final GroupCoordinator? groupCoordinatorOverride;
  final AuthApi? authApiOverride;

  const GroupJoinPage({
    super.key,
    required this.onBack,
    required this.onJoined,
    this.groupApiOverride,
    this.groupCoordinatorOverride,
    this.authApiOverride,
  });

  @override
  State<GroupJoinPage> createState() => _GroupJoinPageState();
}

class _GroupJoinPageState extends State<GroupJoinPage> {
  GroupCoordinator get _coordinator =>
      widget.groupCoordinatorOverride ?? ApiModule.instance.groupCoordinator;

  AuthApi get _authApi => widget.authApiOverride ?? ApiModule.instance.authApi;

  final TextEditingController codeController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  bool _joining = false;
  String? _error;

  void _snack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? TuuurTheme.brandOrange,
      ),
    );
  }

  Future<void> joinGame() async {
    if (_joining) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      final enteredCode = codeController.text.trim();

      if (enteredCode.isEmpty) {
        setState(() {
          _joining = false;
          _error = 'Veuillez entrer un code de partie.';
        });
        _snack(_error!, color: TuuurTheme.brandOrange);
        return;
      }

      // Obtenir l'ID de l'utilisateur actuel
      final authStore = MyAuthStore.of(context);

      if (!authStore.isAuthenticated) {
        final nickname = nicknameController.text.trim();
        if (nickname.isEmpty) {
          setState(() {
            _joining = false;
            _error = 'Veuillez entrer un pseudo.';
          });
          _snack(_error!, color: TuuurTheme.brandOrange);
          return;
        }

        final res = await _authApi.loginAsGuest(nickName: nickname);
        if (res.ok && res.data != null) {
          await authStore.signInWithSession(res.data!);
        } else {
          setState(() {
            _joining = false;
            _error = res.message ?? 'Erreur lors de la connexion invité.';
          });
          _snack(_error!, color: TuuurTheme.brandOrange);
          return;
        }
      }

      final currentUserId = authStore.user?.id;

      // Rejoindre via le coordinateur
      final success = await _coordinator.joinParty(
        enteredCode,
        currentUserId: currentUserId,
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _joining = false;
          _error = 'Impossible de rejoindre la partie. Code invalide ?';
        });
        _snack(_error!, color: TuuurTheme.brandOrange);
        return;
      }

      final party = _coordinator.store.currentParty;
      final partyId = party?.id ?? '';
      final lobbyCode = party?.code ?? enteredCode;

      setState(() => _joining = false);
      widget.onJoined(partyId: partyId, code: lobbyCode);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = 'Erreur: $e';
      });
      _snack(_error!, color: TuuurTheme.brandOrange);
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required bool isValid,
    required double fontSize,
    double? letterSpacing,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hintText,
      hintStyle: TextStyle(
        color: TuuurTheme.brandGray.withOpacity(0.5),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
      ),
      filled: true,
      fillColor: TuuurTheme.brandDarkGray.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: TuuurTheme.brandOrange.withOpacity(0.3),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TuuurTheme.brandOrange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isValid
              ? TuuurTheme.brandGreen
              : TuuurTheme.brandOrange.withOpacity(0.3),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      suffixIcon: isValid
          ? const Icon(Icons.check_circle, color: TuuurTheme.brandGreen)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = MyAuthStore.of(context).isAuthenticated;

    return LayoutBuilder(
      builder: (context, outer) {
        final narrow = outer.maxWidth < 420;
        final code = codeController.text.trim();
        final nickname = nicknameController.text.trim();

        final header = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Rejoindre une partie',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandLightGray,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  GestureDetector(
                    onTap: _joining ? null : widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: TuuurStyles.pill,
                      child: const FaIcon(
                        FontAwesomeIcons.arrowLeft,
                        color: TuuurTheme.brandLightGray,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Rejoindre une partie',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ),
                ],
              );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header.animate().fadeIn().slideX(begin: -0.25),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: TuuurTheme.brandOrange),
                ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.all(narrow ? 20 : 28),
                  decoration: TuuurStyles.gamingCard,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final vw = box.maxWidth;
                      final isVeryNarrow = vw < 340;

                      final iconSize = isVeryNarrow ? 64.0 : 80.0;
                      final titleSize = isVeryNarrow ? 20.0 : 24.0;
                      final codeFont = isVeryNarrow ? 18.0 : 20.0;
                      final vertical = isVeryNarrow ? 10.0 : 14.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: TuuurTheme.brandOrange.withOpacity(0.2),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.rocket,
                                color: TuuurTheme.brandOrange,
                                size: 28,
                              ),
                            ),
                          ),
                          SizedBox(height: vertical + 6),
                          Text(
                            'Entrez le code à 6 chiffres',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                          SizedBox(height: vertical + 6),
                          TextField(
                            controller: codeController,
                            enabled: !_joining,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: TuuurTheme.brandLightGray,
                              fontSize: codeFont,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.6,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: '••••••',
                              isValid: code.length == 6,
                              fontSize: codeFont,
                              letterSpacing: 1.6,
                            ),
                            onSubmitted: (_) =>
                                isAuthenticated ? joinGame() : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (!isAuthenticated) ...[
                            SizedBox(height: vertical + 6),
                            Text(
                              'Choisissez un pseudo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                                color: TuuurTheme.brandLightGray,
                              ),
                            ),
                            SizedBox(height: vertical + 6),
                            TextField(
                              controller: nicknameController,
                              enabled: !_joining,
                              keyboardType: TextInputType.text,
                              maxLength: 50,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: TuuurTheme.brandLightGray,
                                fontSize: codeFont,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: 'Pseudo',
                                isValid: nickname.isNotEmpty,
                                fontSize: codeFont,
                              ),
                              onSubmitted: (_) => joinGame(),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                          SizedBox(height: vertical),
                          SizedBox(
                            width: double.infinity,
                            child: GamingButtonPrimary(
                              text: _joining ? 'Connexion…' : 'Rejoindre',
                              onPressed: _joining ? null : joinGame,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.25),
            ],
          ),
        );
      },
    );
  }
}
