import 'dart:convert';

import 'package:edugest/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  AuthSessionService._();

  static const String _userKey = 'edugest_current_user';
  static const String _schoolKey = 'edugest_active_school_id';

  static Future<void> saveSession(AppUser user, {String? schoolId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));

    if (schoolId != null && schoolId.trim().isNotEmpty) {
      await prefs.setString(_schoolKey, schoolId.trim());
    } else {
      await prefs.remove(_schoolKey);
    }
  }

  static Future<void> saveActiveSchool(String? schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    if (schoolId == null || schoolId.trim().isEmpty) {
      await prefs.remove(_schoolKey);
      return;
    }
    await prefs.setString(_schoolKey, schoolId.trim());
  }

  static Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return null;
      }
      return AppUser.fromMap(map);
    } catch (_) {
      await prefs.remove(_userKey);
      return null;
    }
  }

  static Future<String?> loadActiveSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_schoolKey);
  }

  static Future<Map<String, dynamic>> loadSession() async {
    final user = await loadUser();
    final schoolId = await loadActiveSchoolId();
    return {'user': user, 'schoolId': schoolId};
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_schoolKey);
  }
}
