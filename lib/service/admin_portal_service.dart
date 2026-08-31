import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AdminPortalService {
  static const String _schoolsKey = 'edugest_admin_schools';
  static const String _paymentMethodsKey = 'edugest_admin_payment_methods';
  static const String _promotionsKey = 'edugest_admin_promotions';

  static List<Map<String, dynamic>> _defaultSchools() {
    return [
      {
        'id': 'school-001',
        'name': 'École de l’Excellence',
        'status': 'active',
        'founderName': 'M. Ibrahima Diop',
        'founderPhone': '+221 77 123 45 67',
        'whatsapp': '+221 77 123 45 67',
        'subscription': 'Premium',
        'city': 'Dakar',
      },
      {
        'id': 'school-002',
        'name': 'Collège Saint Martin',
        'status': 'suspended',
        'founderName': 'Mme Awa Sall',
        'founderPhone': '+221 76 654 32 10',
        'whatsapp': '+221 76 654 32 10',
        'subscription': 'Basic',
        'city': 'Thiès',
      },
      {
        'id': 'school-003',
        'name': 'Complexe Scolaire Bintou',
        'status': 'active',
        'founderName': 'M. Cheikh Ndoye',
        'founderPhone': '+221 70 987 65 43',
        'whatsapp': '+221 70 987 65 43',
        'subscription': 'Pro',
        'city': 'Saint-Louis',
      },
    ];
  }

  static List<Map<String, dynamic>> _defaultPaymentMethods() {
    return [
      {
        'id': 'mtn',
        'label': 'MTN Mobile Money',
        'number': '+221 77 000 00 00',
        'accountHolder': 'EduGest',
        'isActive': true,
      },
      {
        'id': 'orange',
        'label': 'Orange Money',
        'number': '+221 76 000 00 00',
        'accountHolder': 'EduGest',
        'isActive': true,
      },
    ];
  }

  static List<Map<String, dynamic>> _defaultPromotions() {
    return [
      {
        'id': 'promo-1',
        'title': 'Offre de lancement',
        'description': '1 mois offert pour les nouveaux établissements.',
        'discountPct': 20,
        'isActive': true,
      },
      {
        'id': 'promo-2',
        'title': 'Pack école complète',
        'description': 'Réduction sur les abonnements premium pour 3 écoles.',
        'discountPct': 15,
        'isActive': false,
      },
      {
        'id': 'promo-3',
        'title': 'Retour de l’année',
        'description': 'Promotion spéciale pour la reprise des classes.',
        'discountPct': 10,
        'isActive': true,
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> loadSchools() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schoolsKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setString(_schoolsKey, jsonEncode(_defaultSchools()));
      return _defaultSchools();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return _defaultSchools();
      return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      await prefs.setString(_schoolsKey, jsonEncode(_defaultSchools()));
      return _defaultSchools();
    }
  }

  static Future<void> saveSchools(List<Map<String, dynamic>> schools) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolsKey, jsonEncode(schools));
  }

  static Future<List<Map<String, dynamic>>> loadPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentMethodsKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setString(_paymentMethodsKey, jsonEncode(_defaultPaymentMethods()));
      return _defaultPaymentMethods();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return _defaultPaymentMethods();
      return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      await prefs.setString(_paymentMethodsKey, jsonEncode(_defaultPaymentMethods()));
      return _defaultPaymentMethods();
    }
  }

  static Future<void> savePaymentMethods(List<Map<String, dynamic>> methods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paymentMethodsKey, jsonEncode(methods));
  }

  static Future<List<Map<String, dynamic>>> loadPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_promotionsKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setString(_promotionsKey, jsonEncode(_defaultPromotions()));
      return _defaultPromotions();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return _defaultPromotions();
      return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      await prefs.setString(_promotionsKey, jsonEncode(_defaultPromotions()));
      return _defaultPromotions();
    }
  }

  static Future<void> savePromotions(List<Map<String, dynamic>> promotions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promotionsKey, jsonEncode(promotions));
  }
}
