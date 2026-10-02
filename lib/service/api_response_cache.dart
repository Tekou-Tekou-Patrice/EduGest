import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponseCache {
  ApiResponseCache._();

  static const String _prefix = 'edugest_api_cache_';

  static String _cacheKey({
    required String userId,
    required String? schoolId,
    required String requestUri,
  }) {
    final identity = '$userId|${schoolId ?? ''}|$requestUri';
    final digest = sha256.convert(utf8.encode(identity));
    return '$_prefix$digest';
  }

  static Future<void> store({
    required String userId,
    required String? schoolId,
    required String requestUri,
    required dynamic data,
  }) async {
    final encoded = jsonEncode({'data': data});
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cacheKey(userId: userId, schoolId: schoolId, requestUri: requestUri),
      encoded,
    );
  }

  static Future<({bool found, dynamic data})> read({
    required String userId,
    required String? schoolId,
    required String requestUri,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _cacheKey(
      userId: userId,
      schoolId: schoolId,
      requestUri: requestUri,
    );
    final encoded = preferences.getString(key);
    if (encoded == null) return (found: false, data: null);

    final envelope = jsonDecode(encoded);
    if (envelope is! Map<String, dynamic> || !envelope.containsKey('data')) {
      throw const FormatException('Invalid cached API response');
    }
    return (found: true, data: envelope['data']);
  }
}
