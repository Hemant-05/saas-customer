import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CustomerOfflineCacheService {
  CustomerOfflineCacheService._();

  static const String _prefix = 'customer_offline_cache_';

  static Future<void> writeJson(String key, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'value': value,
      }),
    );
  }

  static Future<Map<String, dynamic>?> readJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final value = decoded['value'];
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
    return null;
  }
}
