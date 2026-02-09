import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/tuuuur_theme.dart';
import '../../widgets/gaming_widgets.dart';

class GroupJoinPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function({required String code}) onJoined;

  const GroupJoinPage({
    super.key,
    required this.onBack,
    required this.onJoined,
  });

  @override
  State<GroupJoinPage> createState() => _GroupJoinPageState();
}

class _GroupJoinPageState extends State<GroupJoinPage> {
  final TextEditingController codeController = TextEditingController();
  bool isValidCode = false;

  @override
  void initState() {
    super.initState();
    codeController.addListener(_validateCode);
  }

  void _validateCode() {
    final code = codeController.text.trim().toUpperCase();
    setState(() {
      isValidCode = code.startsWith('TUR-') && code.length >= 8;
    });
  }

  void joinGame() {
    if (isValidCode) {
      widget.onJoined(code: codeController.text.trim().toUpperCase());
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        final narrow = outer.maxWidth < 420;

        // ---------- HEADER ----------
        final header = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
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
                  const SizedBox(height: 10),
                  const Text(
                    'Rejoindre une partie',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 26, // compact sur mobile
                      fontWeight: FontWeight.w600,
                      color: TuuurTheme.brandLightGray,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
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

        // ---------- CARD ----------
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header.animate().fadeIn().slideX(begin: -0.25),
            const SizedBox(height: 24),

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
                    final descSize = 14.0;
                    final codeFont = isVeryNarrow ? 18.0 : 20.0;
                    final vertical = isVeryNarrow ? 10.0 : 14.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icone
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

                        // Titre
                        Text(
                          'Entrez le code de la partie',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: TuuurTheme.brandLightGray,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          'Demandez le code à l\'organisateur ou scannez le QR code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TuuurTheme.brandGray,
                            fontSize: descSize,
                          ),
                        ),
                        SizedBox(height: vertical + 6),

                        // Input du code
                        TextField(
                          controller: codeController,
                          textAlign: TextAlign.center,
                          // autofocus: true,
                          style: TextStyle(
                            color: TuuurTheme.brandLightGray,
                            fontSize: codeFont,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'TUR-0000',
                            hintStyle: TextStyle(
                              color: TuuurTheme.brandGray.withOpacity(0.5),
                              fontSize: codeFont,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                            filled: true,
                            fillColor: TuuurTheme.brandDarkGray.withOpacity(
                              0.3,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: TuuurTheme.brandOrange.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: TuuurTheme.brandOrange,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isValidCode
                                    ? TuuurTheme.brandGreen
                                    : TuuurTheme.brandOrange.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            suffixIcon: isValidCode
                                ? const Icon(
                                    Icons.check_circle,
                                    color: TuuurTheme.brandGreen,
                                  )
                                : null,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => joinGame(),
                        ),
                        SizedBox(height: vertical),

                        // Bouton Rejoindre
                        SizedBox(
                          width: double.infinity,
                          child: GamingButtonPrimary(
                            text: 'Rejoindre',
                            onPressed: isValidCode ? joinGame : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bouton Scanner
                        SizedBox(
                          width: double.infinity,
                          child: GamingButtonSecondary(
                            text: 'Scanner QR Code',
                            onPressed: () {
                              // TODO: Implement QR scanner
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Scanner QR non disponible en démo',
                                  ),
                                  backgroundColor: TuuurTheme.brandOrange,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: vertical + 6),

                        // Tips
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: TuuurTheme.brandGreen.withOpacity(0.1),
                            border: Border.all(
                              color: TuuurTheme.brandGreen.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.lightbulb,
                                color: TuuurTheme.brandGreen,
                                size: 16,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Le code commence toujours par "TUR-" suivi de 4 chiffres',
                                  style: TextStyle(
                                    color: TuuurTheme.brandGreen,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.25),
          ],
        );
      },
    );
  }
}
