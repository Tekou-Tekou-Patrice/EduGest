import 'package:flutter/material.dart';
import '../models/school_info.dart';
import 'api_service.dart';

class SchoolNotifier extends ValueNotifier<SchoolInfo?> {
  SchoolNotifier() : super(null);

  bool _isFetching = false;

  Future<void> fetchSchoolInfo() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final info = await ApiService.getSchoolInfo();
      if (info != null) {
        value = info;
      }
    } catch (e) {
      debugPrint("SchoolNotifier fetch error: $e");
    } finally {
      _isFetching = false;
    }
  }

  void setSchoolInfo(SchoolInfo info) {
    value = info;
  }
}

final currentSchoolNotifier = SchoolNotifier();
