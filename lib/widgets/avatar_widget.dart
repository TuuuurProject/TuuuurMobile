import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/tuuuur_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatarBase64;
  final String fallbackText;
  final double size;

  const AvatarWidget({
    super.key,
    required this.avatarBase64,
    required this.fallbackText,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        // Extraire les données base64 du data URI
        final base64String = avatarBase64!.contains(',')
            ? avatarBase64!.split(',').last
            : avatarBase64!;
        final Uint8List bytes = base64Decode(base64String);

        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback();
            },
          ),
        );
      } catch (e) {
        return _buildFallback();
      }
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TuuurTheme.brandPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            color: TuuurTheme.brandPurple,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
