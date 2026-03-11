import 'dart:convert';

/// Fixes UTF-8 encoding issues from SignalR WebSocket data (UTF-8 misinterpreted as Latin1)

/// Fixes UTF-8 mojibake by re-encoding Latin1 bytes as UTF-8
String fixUtf8Mojibake(String s) {
  if (s.isEmpty) return s;

  try {
    return utf8.decode(latin1.encode(s));
  } catch (_) {
    return s;
  }
}

/// Applies encoding fix to nullable strings
String? fixUtf8MojibakeNullable(String? s) {
  return s != null ? fixUtf8Mojibake(s) : null;
}

/// Recursively applies encoding fix to all strings in a JSON map
Map<String, dynamic> fixJsonEncoding(Map<String, dynamic> json) {
  return json.map((key, value) {
    if (value is String) {
      return MapEntry(key, fixUtf8Mojibake(value));
    } else if (value is Map<String, dynamic>) {
      return MapEntry(key, fixJsonEncoding(value));
    } else if (value is List) {
      return MapEntry(key, _fixListEncoding(value));
    }
    return MapEntry(key, value);
  });
}

/// Recursively applies encoding fix to lists
List<dynamic> _fixListEncoding(List<dynamic> list) {
  return list.map((item) {
    if (item is String) {
      return fixUtf8Mojibake(item);
    } else if (item is Map<String, dynamic>) {
      return fixJsonEncoding(item);
    } else if (item is List) {
      return _fixListEncoding(item);
    }
    return item;
  }).toList();
}
