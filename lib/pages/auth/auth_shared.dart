import 'package:flutter/material.dart';
import 'package:tuuuur_flutter/navigation/app_router.dart';

import '../../theme/tuuuur_theme.dart';
import '../../navigation/app_messengers.dart';

/// Snackbars homogènes dans tous les écrans auth.
class AuthSnackbars {
  static void show(
    String message, {
    Color color = TuuurTheme.brandOrange,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
  }
}


/// Validations partagées (évite la duplication des regex).
class AuthValidators {
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  static bool isValidPassword(String password) =>
      password.length >= 8 &&
      _upper.hasMatch(password) &&
      _lower.hasMatch(password) &&
      _digit.hasMatch(password);

  static bool isSixDigitCode(String code) => _sixDigits.hasMatch(code);
}

/// Décoration unique pour tous les TextField auth.
InputDecoration authInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: TuuurTheme.brandGray.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: TuuurTheme.brandDarkGray.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: TuuurTheme.brandPurple.withValues(alpha: 0.3),
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
          color: TuuurTheme.brandPurple.withValues(alpha: 0.3),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );

/// Carte centrée avec style "gamingCard".
class AuthCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const AuthCard({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        decoration: TuuurStyles.gamingCard,
        child: child,
      ),
    );
  }
}

/// Label + champ (remplace _FieldLabel et _LabeledField).
class AuthLabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final double gap;

  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.gap = 6,
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
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

/// Champ password réutilisable avec bouton "œil" intégré.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '••••••••',
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AuthLabeledField(
      label: widget.label,
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        obscureText: _obscured,
        style: const TextStyle(color: TuuurTheme.brandLightGray),
        decoration: authInputDecoration(widget.hint).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscured ? Icons.visibility : Icons.visibility_off,
              color: TuuurTheme.brandGray,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
      ),
    );
  }
}

/// PopScope commun (évite la répétition du même bloc).
class AuthPopScope extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;

  const AuthPopScope({
    super.key,
    required this.child,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onBack();
      },
      child: child,
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final String title;
  final double cardMaxWidth;
  final Widget body;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.body,
    this.cardMaxWidth = 500,
  });

  @override
  Widget build(BuildContext context) {
    return AuthPopScope(
      onBack: () => context.goBack(),
      child: Scaffold(
        backgroundColor: TuuurTheme.brandDark,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goBack(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AuthCard(
            maxWidth: cardMaxWidth,
            child: body,
          ),
        ),
      ),
    );
  }
}
