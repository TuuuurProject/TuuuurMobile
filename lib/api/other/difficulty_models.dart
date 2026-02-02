import '../api_helpers.dart';

/// Difficulty DTO
class DifficultyDto {
  final int? id;
  final String label;

  DifficultyDto({
    this.id,
    required this.label,
  });

  factory DifficultyDto.fromJson(Map<String, dynamic> j) {
    // Tolerates multiple API formats
    final dynamicId = j['id'] ?? j['difficultyId'];
    final id = asInt(dynamicId);

    final label = asString(
          j['label'] ?? j['name'] ?? j['title'],
        ) ??
        (id?.toString() ?? '');

    return DifficultyDto(
      id: id,
      label: label,
    );
  }
}