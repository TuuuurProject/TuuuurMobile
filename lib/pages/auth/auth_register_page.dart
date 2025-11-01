import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';
import '../../navigation/app_router.dart';
import '../../navigation/route_history.dart';

class AuthRegisterPage extends StatefulWidget {
  const AuthRegisterPage({super.key});

  @override
  State<AuthRegisterPage> createState() => _AuthRegisterPageState();
}

class _AuthRegisterPageState extends State<AuthRegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isObscure1 = true;
  bool isObscure2 = true;
  bool isLoading = false;

  Future<void> handleRegister() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès !'),
          backgroundColor: TuuurTheme.brandGreen,
        ),
      );
      context.goBack();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // le système a déjà géré le pop
        RouteHistory.instance.navigateBack(context);
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

            // Header matching Vue.js exactly
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.userPlus,
                      color: TuuurTheme.brandLightGray,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: TuuurTheme.brandLightGray,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TuuurTheme.brandGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: TuuurTheme.brandGreen.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Gratuit et rapide',
                    style: TextStyle(
                      color: TuuurTheme.brandLightGray,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form container
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: TuuurStyles.gamingCard,
                child: Column(
                  children: [
                    // Username field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pseudo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: usernameController,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Choisissez un pseudo',
                            hintStyle: TextStyle(
                              color: TuuurTheme.brandGray.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: TuuurTheme.brandDarkGray.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: TuuurTheme.brandPurple.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: InputDecoration(
                            hintText: 'vous@exemple.com',
                            hintStyle: TextStyle(
                              color: TuuurTheme.brandGray.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: TuuurTheme.brandDarkGray.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: TuuurTheme.brandPurple.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mot de passe',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: passwordController,
                          obscureText: isObscure1,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: TuuurTheme.brandGray.withOpacity(0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscure1
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: TuuurTheme.brandGray,
                              ),
                              onPressed: () =>
                                  setState(() => isObscure1 = !isObscure1),
                            ),
                            filled: true,
                            fillColor: TuuurTheme.brandDarkGray.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: TuuurTheme.brandPurple.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Confirm password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirmer le mot de passe',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: isObscure2,
                          style: const TextStyle(
                            color: TuuurTheme.brandLightGray,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: TuuurTheme.brandGray.withOpacity(0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscure2
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: TuuurTheme.brandGray,
                              ),
                              onPressed: () =>
                                  setState(() => isObscure2 = !isObscure2),
                            ),
                            filled: true,
                            fillColor: TuuurTheme.brandDarkGray.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: TuuurTheme.brandPurple.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
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
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GamingButtonSecondary(
                          text: 'Annuler',
                          onPressed: () => context.goBack(),
                        ),
                        const SizedBox(width: 12),
                        GamingButtonPrimary(
                          text: isLoading ? 'Création...' : 'Créer le compte',
                          onPressed: isLoading ? null : handleRegister,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Login link
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
                          onPressed: () {
                            context.push('/auth/login');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: TuuurTheme.brandPurple.withOpacity(0.3),
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
}
