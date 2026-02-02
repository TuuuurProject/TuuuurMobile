import '../api_helpers.dart';

class ThemeItemDto {
  final int? id;
  final String icon;
  final String label;

  ThemeItemDto({this.id, required this.icon, required this.label});

  factory ThemeItemDto.fromJson(Map<String, dynamic> j) => ThemeItemDto(
        id: (j['id'] is int) ? j['id'] as int : int.tryParse('${j['id']}'),
        icon: (j['icon'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
      );
}

class ThemeDto {
  final int? id;
  final String key;  
  final String name; 
  final String? description;
  final String? icon; 

  ThemeDto({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    this.icon,
  });

  factory ThemeDto.fromJson(Map<String, dynamic> j) {
    // Handle multiple possible keys from API
    final dynamicId = j['id'] ?? j['themeId'];
    final id = asInt(dynamicId);
    final code = asString(j['code'] ?? j['key'] ?? j['slug']) ?? (id?.toString() ?? '');
    final name = asString(j['name'] ?? j['label'] ?? j['title']) ?? code;
    final desc = asString(j['description'] ?? j['details']);
    final icon = asString(j['icon'] ?? j['faIcon'] ?? j['iconName']);

    return ThemeDto(
      id: id,
      key: code,
      name: name,
      description: desc,
      icon: icon,
    );
  }
}
