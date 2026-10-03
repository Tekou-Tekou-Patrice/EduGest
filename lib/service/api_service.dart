import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_response_cache.dart';
import 'auth_session_service.dart';
import 'network_status_service.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_notifier.dart';
import '../pages/login_page.dart';

import '../models/app_user.dart';
import '../models/student.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/grade.dart';
import '../models/event.dart';
import '../models/absence.dart';
import '../models/sanction.dart';
import '../models/payment.dart';
import '../models/school_info.dart';
import '../models/bulletin_publication.dart';
import '../models/audit_log.dart';
import '../models/academic_year_recap.dart';
import '../models/lesson.dart';
import '../models/schedule.dart';
import '../models/school.dart';
import '../models/teacher.dart';
import '../models/exam_class.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  static final Dio _dio = _createDio();

  static String? activeSchoolId;
  static AppUser? currentUser;

  static const _apiBaseUrl = String.fromEnvironment('EDUGEST_API_BASE_URL');

  static String get _localBaseUrl {
    final configuredUrl = _apiBaseUrl.trim();
    final baseUrl = kIsWeb
        ? Uri.base.origin
        : configuredUrl.isNotEmpty
        ? configuredUrl
        : 'https://edugest.duckdns.org/';
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _localBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = currentUser?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (activeSchoolId != null) {
            options.headers['X-School-Id'] = activeSchoolId;
          }
          return handler.next(options);
        },
      ),
    );
    _installCacheInterceptors(dio);
    return dio;
  }

  static void _installCacheInterceptors(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['edugestCacheUserId'] = currentUser?.id ?? 'anonymous';
          options.extra['edugestCacheSchoolId'] = activeSchoolId;
          handler.next(options);
        },
        onResponse: (response, handler) async {
          NetworkStatusService.reportServerAvailable();
          if (response.requestOptions.method.toUpperCase() == 'GET' &&
              response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            try {
              await ApiResponseCache.store(
                userId:
                    response.requestOptions.extra['edugestCacheUserId']
                        as String,
                schoolId:
                    response.requestOptions.extra['edugestCacheSchoolId']
                        as String?,
                requestUri: response.requestOptions.uri.toString(),
                data: response.data,
              );
            } on Object catch (error) {
              debugPrint('Unable to store API response cache: $error');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final serverFailure = statusCode != null && statusCode >= 500;
          final connectivityFailure =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;
          if (serverFailure || connectivityFailure) {
            NetworkStatusService.reportServerFailure();
          }

          final request = error.requestOptions;
          if (request.method.toUpperCase() == 'GET' &&
              (serverFailure || connectivityFailure)) {
            try {
              final cached = await ApiResponseCache.read(
                userId: request.extra['edugestCacheUserId'] as String,
                schoolId: request.extra['edugestCacheSchoolId'] as String?,
                requestUri: request.uri.toString(),
              );
              if (cached.found) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: request,
                    data: cached.data,
                    statusCode: 200,
                    extra: const {'edugest-cache': 'HIT'},
                  ),
                );
                return;
              }
            } on Object catch (cacheError) {
              debugPrint('Unable to read API response cache: $cacheError');
            }
          }
          if (statusCode == 401 &&
              !error.requestOptions.path.contains('/api/users/login') &&
              !error.requestOptions.path.contains('/api/users/register')) {
            clearActiveUser();
            activeSchoolId = null;
            await AuthSessionService.clearSession();
            rootNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static void init(String baseUrl, String? schoolId) {
    _dio.options.baseUrl = baseUrl;
    activeSchoolId = schoolId;
    _dio.interceptors.clear();
    _installCacheInterceptors(_dio);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = currentUser?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (activeSchoolId != null) {
            options.headers['X-School-Id'] = activeSchoolId;
          }
          return handler.next(options);
        },
      ),
    );
  }

  static void setActiveUser(AppUser user) => currentUser = user;
  static void clearActiveUser() => currentUser = null;
  static void setActiveSchool(String? schoolId) => activeSchoolId = schoolId;

  static List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is List)
      return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  static String _errorMessage(DioException e) {
    final localizations = AppLocalizations(appLocale.value);
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return localizations.translate(
        NetworkStatusService.isOnline.value == false
            ? 'networkError'
            : 'serviceUnavailable',
      );
    }
    if (e.response?.statusCode == 401) {
      return localizations.translate('sessionExpired');
    }
    if (e.response?.statusCode == 403) {
      return localizations.translate('permissionDenied');
    }
    if (e.requestOptions.path.startsWith('/api/staff-attendance') &&
        e.response?.data is Map) {
      final message = e.response?.data['message']?.toString() ?? '';
      if (message.contains('à partir de 6 h')) {
        return localizations.translate('staffAttendanceAvailableAtSix');
      }
      if (message.contains('invalide ou expiré')) {
        return localizations.translate('staffAttendanceInvalidQr');
      }
      if (message.contains('déjà été enregistrés')) {
        return localizations.translate('staffAttendanceAlreadyComplete');
      }
    }
    if (e.response?.data is Map &&
        e.response?.data['message']?.toString().contains(
              'Plusieurs comptes utilisent ce numéro',
            ) ==
            true) {
      return localizations.translate('loginPhoneAmbiguous');
    }
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return localizations.translate('serviceUnavailable');
    }
    if (e.response?.data != null && e.response?.data is Map) {
      final message = e.response?.data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return appLocale.value.languageCode == 'en'
            ? localizations.translate('requestFailed')
            : message;
      }
    }
    return localizations.translate('unexpectedError');
  }

  static String friendlyErrorMessage(Object error) {
    if (error is DioException) return _errorMessage(error);
    return AppLocalizations(appLocale.value).translate('unexpectedError');
  }

  // --- AUTH & USERS ---

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/users/login',
        data: {'username': email, 'password': password},
      );
      final user = AppUser.fromMap(_asMap(response.data));
      return {'success': true, 'user': user};
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> registerAccount({
    required String name,
    String? email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '/api/users/register',
        data: {
          'username': email,
          'name': name,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          'password': password,
          'phone': phone,
          'role': 'MEMBRE',
        },
      );
      final data = _asMap(response.data);
      return {
        'success': true,
        'user': AppUser.fromMap(data),
        'verificationCode': data['verificationCode']?.toString(),
      };
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  static Future<void> verifyRegistration({
    required String userId,
    required String code,
  }) async {
    await _dio.post(
      '/api/users/verify-registration',
      data: {'userId': userId, 'code': code},
    );
  }

  static Future<void> requestPasswordChangeCode(String userId) async {
    await _dio.post('/api/users/$userId/request-password-change-code');
  }

  static Future<void> confirmPasswordChange({
    required String userId,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/users/$userId/confirm-password-change',
      data: {'code': code, 'newPassword': newPassword},
    );
  }

  static Future<void> requestPasswordReset(String contact) async {
    await _dio.post(
      '/api/users/request-password-reset',
      data: {'contact': contact},
    );
  }

  static Future<void> resetPassword({
    required String contact,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/users/reset-password',
      data: {'contact': contact, 'code': code, 'newPassword': newPassword},
    );
  }

  static Future<Map<String, dynamic>> registerStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? registeredByUserId,
    String language = 'fr',
  }) async {
    try {
      final response = await _dio.post(
        '/api/users/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
          if (activeSchoolId != null && int.tryParse(activeSchoolId!) != null)
            'schoolId': int.parse(activeSchoolId!),
          if (registeredByUserId != null)
            'registeredByUserId': registeredByUserId,
          'language': language,
        },
      );
      return {'success': true, 'user': AppUser.fromMap(_asMap(response.data))};
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  static Future<List<AppUser>> getAllStaff() async {
    final response = await _dio.get('/api/users');
    return _asMapList(response.data)
        .map(AppUser.fromMap)
        .where((u) => u.role != UserRole.parent && u.role != UserRole.eleve)
        .toList();
  }

  static Future<List<Teacher>> getTeachers({String? query}) async {
    final response = await _dio.get(
      '/api/scolarite/teachers',
      queryParameters: {if (query != null) 'query': query},
    );
    return _asMapList(response.data).map(Teacher.fromMap).toList();
  }

  static Future<void> saveTeacher(Teacher teacher) async {
    await _dio.post('/api/scolarite/teachers', data: teacher.toMap());
  }

  static Future<void> deleteTeacher(String id) async {
    await _dio.delete('/api/scolarite/teachers/$id');
  }

  static Future<void> deleteUser(String id) async {
    await _dio.delete('/api/users/$id');
  }

  static Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/users/$userId/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  // --- SCHOOLS & SELECTION ---

  static Future<List<School>> getUserSchools(String userId) async {
    final response = await _dio.get('/api/schools/user/$userId');
    return _asMapList(response.data).map(School.fromMap).toList();
  }

  static Future<void> selectSchool({
    required String userId,
    required String schoolId,
  }) async {
    await _dio.post(
      '/api/schools/select',
      queryParameters: {'userId': userId, 'schoolId': schoolId},
    );
  }

  static Future<({String id, String code})> createSchool({
    required String userId,
    required String name,
    String schoolLevel = 'COLLEGE',
    String? address,
    String? phone,
  }) async {
    final response = await _dio.post(
      '/api/schools',
      data: {
        'userId': int.tryParse(userId) ?? userId,
        'name': name,
        'schoolLevel': schoolLevel,
        'address': address ?? '',
        'phone': phone ?? '',
      },
    );
    final data = _asMap(response.data);
    final id = data['id']?.toString();
    final code = data['code']?.toString();
    if (id == null || id.isEmpty || code == null || code.isEmpty) {
      throw const FormatException(
        'School creation response did not contain its id and generated code.',
      );
    }
    return (id: id, code: code);
  }

  static Future<void> joinSchoolByCode({
    required String code,
    required String userId,
  }) async {
    await _dio.post(
      '/api/schools/join',
      queryParameters: {'code': code, 'userId': userId},
    );
  }

  static Future<String> regenerateSchoolCode({
    required String userId,
    required String schoolId,
  }) async {
    final response = await _dio.post(
      '/api/schools/$schoolId/regenerate-code',
      queryParameters: {'userId': userId},
    );
    final data = _asMap(response.data);
    final code = data['code']?.toString();
    if (code == null || code.isEmpty) {
      throw const FormatException('Code introuvable dans la réponse.');
    }
    return code;
  }

  // --- ÉLÈVES & CLASSES ---

  static Future<List<Student>> getStudents({
    String? className,
    String? query,
  }) async {
    final response = await _dio.get(
      '/api/scolarite/students',
      queryParameters: {
        if (className != null && className.isNotEmpty) 'className': className,
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    return _asMapList(response.data).map(Student.fromMap).toList();
  }

  static Future<List<Student>> getParentStudents(String parentId) async {
    final response = await _dio.get(
      '/api/scolarite/parents/$parentId/students',
    );
    return _asMapList(response.data).map(Student.fromMap).toList();
  }

  static Future<Student> saveStudent(Student s) async {
    final data = s.toMap();
    if (s.id.isEmpty || s.id == '0') data.remove('id');
    final response = await _dio.post('/api/scolarite/students', data: data);
    return Student.fromMap(_asMap(response.data));
  }

  static Future<void> deleteStudent(String id) async {
    await _dio.delete('/api/scolarite/students/$id');
  }

  static Future<Student> validateStudent({
    required String studentId,
    required String classroomId,
  }) async {
    final response = await _dio.post(
      '/api/scolarite/students/$studentId/validate',
      queryParameters: {'classroomId': classroomId},
    );
    return Student.fromMap(_asMap(response.data));
  }

  static Future<List<SchoolClass>> getClassrooms() async {
    final response = await _dio.get('/api/scolarite/classrooms');
    return _asMapList(response.data).map(SchoolClass.fromMap).toList();
  }

  static Future<SchoolClass> saveClassroom(SchoolClass c) async {
    final data = c.toMap();
    if (c.id.isEmpty || c.id == '0') data.remove('id');
    final response = await _dio.post('/api/scolarite/classrooms', data: data);
    return SchoolClass.fromMap(_asMap(response.data));
  }

  static Future<SchoolClass> saveClassPromotionSettings({
    required String classId,
    required double threshold,
  }) async {
    final response = await _dio.put(
      '/api/scolarite/classrooms/$classId/promotion',
      data: {'promotionThreshold': threshold},
    );
    return SchoolClass.fromMap(_asMap(response.data));
  }

  static Future<void> deleteClassroom(String id) async {
    await _dio.delete('/api/scolarite/classrooms/$id');
  }

  static Future<ExamClassConfig> getExamClassConfig(String classroomId) async {
    final response = await _dio.get('/api/exam-classes/$classroomId/config');
    return ExamClassConfig.fromMap(_asMap(response.data));
  }

  static Future<ExamClassConfig> saveExamClassConfig(
    String classroomId,
    ExamClassConfig config,
  ) async {
    final response = await _dio.put(
      '/api/exam-classes/$classroomId/config',
      data: config.toMap(),
    );
    return ExamClassConfig.fromMap(_asMap(response.data));
  }

  static Future<List<StudentExamStatus>> getExamClassStudents(
    String classroomId,
  ) async {
    final response = await _dio.get('/api/exam-classes/$classroomId/students');
    return _asMapList(response.data).map(StudentExamStatus.fromMap).toList();
  }

  static Future<StudentExamStatus> saveExamStudentStatus(
    String classroomId,
    StudentExamStatus status,
  ) async {
    final response = await _dio.put(
      '/api/exam-classes/$classroomId/students/${status.studentId}',
      data: status.toMap(),
    );
    return StudentExamStatus.fromMap(_asMap(response.data));
  }

  static Future<StudentExamStatus?> getParentExamStatus({
    required String studentId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/exam-classes/parent/students/$studentId',
      );
      return StudentExamStatus.fromMap(_asMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 400) {
        return null;
      }
      rethrow;
    }
  }

  // --- ACADÉMIQUE ---

  static Future<List<ScheduleItem>> getSchedule({
    String? className,
    String? teacherName,
    String? day,
  }) async {
    final response = await _dio.get(
      '/api/academique/schedule',
      queryParameters: {
        if (className != null) 'className': className,
        if (teacherName != null) 'teacherName': teacherName,
        if (day != null) 'day': day,
      },
    );
    return _asMapList(response.data).map(ScheduleItem.fromMap).toList();
  }

  static Future<void> saveScheduleItem(ScheduleItem item) async {
    final data = item.toMap();
    if (item.id.isEmpty || item.id == '0') data.remove('id');
    await _dio.post('/api/academique/schedule', data: data);
  }

  static Future<void> deleteScheduleItem(String id) async {
    await _dio.delete('/api/academique/schedule/$id');
  }

  static Future<List<Lesson>> getLessons({String? className}) async {
    final response = await _dio.get(
      '/api/academique/lessons',
      queryParameters: {if (className != null) 'className': className},
    );
    return _asMapList(response.data).map(Lesson.fromMap).toList();
  }

  static Future<List<Map<String, dynamic>>> getLessonsByClass(
    String className,
  ) async {
    final response = await _dio.get(
      '/api/academique/lessons',
      queryParameters: {'className': className},
    );
    return _asMapList(response.data);
  }

  static Future<List<Map<String, dynamic>>> getAllLessons() async {
    final response = await _dio.get('/api/academique/lessons');
    return _asMapList(response.data);
  }

  static Future<List<Map<String, dynamic>>> getMyLessons(
    String teacherId,
  ) async {
    final response = await _dio.get(
      '/api/academique/lessons',
      queryParameters: {'teacherId': teacherId},
    );
    return _asMapList(response.data);
  }

  static Future<void> saveLesson(Map<String, dynamic> lessonData) async {
    await _dio.post('/api/academique/lessons', data: lessonData);
  }

  static Future<void> submitGrades(Map<String, dynamic> gradesData) async {
    await _dio.post('/api/academique/grades', data: gradesData);
  }

  static Future<List<Exam>> getExams({
    String? className,
    String? teacherName,
  }) async {
    final response = await _dio.get(
      '/api/academique/exams',
      queryParameters: {
        if (className != null && className.isNotEmpty) 'className': className,
        if (teacherName != null && teacherName.isNotEmpty)
          'teacherName': teacherName,
      },
    );
    return _asMapList(response.data).map(Exam.fromMap).toList();
  }

  static Future<List<Grade>> getGradesByExam(String examId) async {
    final response = await _dio.get('/api/academique/exams/$examId/grades');
    return _asMapList(response.data).map(Grade.fromMap).toList();
  }

  static Future<void> updateGrade(Grade grade) async {
    await _dio.put('/api/academique/grades/${grade.id}', data: grade.toMap());
  }

  static Future<void> updateGrades(List<Grade> grades) async {
    await _dio.put(
      '/api/academique/grades/batch',
      data: grades.map((grade) => grade.toMap()).toList(),
    );
  }

  static Future<List<Subject>> getSubjects() async {
    final response = await _dio.get('/api/academique/subjects');
    return _asMapList(response.data).map(Subject.fromMap).toList();
  }

  static Future<void> saveSubject(Subject s) async {
    final data = s.toMap();
    if (s.id.isEmpty || s.id == '0') data.remove('id');
    await _dio.post('/api/academique/subjects', data: data);
  }

  static Future<void> deleteSubject(String id) async {
    await _dio.delete('/api/academique/subjects/$id');
  }

  static Future<List<Event>> getEvents() async {
    final response = await _dio.get('/api/academique/events');
    return _asMapList(response.data).map(Event.fromMap).toList();
  }

  static Future<void> saveEvent(Event event) async {
    final data = event.toMap();
    if (event.id.isEmpty || event.id == '0') data.remove('id');
    await _dio.post('/api/academique/events', data: data);
  }

  static Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/academique/events/$id');
  }

  static Future<ScheduleItem?> getCurrentSession(String teacherName) async {
    final schedule = await getSchedule(teacherName: teacherName);
    final now = DateTime.now();
    final today = switch (now.weekday) {
      DateTime.monday => 'Lundi',
      DateTime.tuesday => 'Mardi',
      DateTime.wednesday => 'Mercredi',
      DateTime.thursday => 'Jeudi',
      DateTime.friday => 'Vendredi',
      DateTime.saturday => 'Samedi',
      _ => 'Dimanche',
    };

    for (final item in schedule) {
      if (item.isBreak ||
          item.day.trim().toLowerCase() != today.toLowerCase()) {
        continue;
      }
      final start = _parseScheduleTime(item.startTime);
      final end = _parseScheduleTime(item.endTime);
      if (start == null || end == null) continue;

      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      final currentMinutes = now.hour * 60 + now.minute;
      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        return item;
      }
    }
    return null;
  }

  static ({int hour, int minute})? _parseScheduleTime(String value) {
    final match = RegExp(r'^\s*(\d{1,2})[:.]([0-5]\d)').firstMatch(value);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23) return null;
    return (hour: hour, minute: minute);
  }

  // --- POINTAGE PROFESSEURS ---

  static Future<List<Map<String, dynamic>>> getTeacherRoomChecks({
    String? teacherId,
    DateTime? date,
  }) async {
    final response = await _dio.get(
      '/api/academique/teacher-room-checks',
      queryParameters: {
        if (teacherId != null) 'teacherId': teacherId,
        if (date != null) 'date': date.toIso8601String().substring(0, 10),
      },
    );
    return _asMapList(response.data);
  }

  static Future<void> saveTeacherRoomCheck(Map<String, dynamic> data) async {
    await _dio.post('/api/academique/teacher-room-checks', data: data);
  }

  static Future<Map<String, dynamic>> getStaffAttendanceQr() async {
    final response = await _dio.get('/api/staff-attendance/qr/today');
    return _asMap(response.data);
  }

  static Future<Map<String, dynamic>> scanStaffAttendanceQr(
    String token,
  ) async {
    final response = await _dio.post(
      '/api/staff-attendance/scan',
      data: {'token': token},
    );
    return _asMap(response.data);
  }

  static Future<List<Map<String, dynamic>>> getStaffAttendanceReport(
    DateTime month,
  ) async {
    final response = await _dio.get(
      '/api/staff-attendance/report',
      queryParameters: {
        'month':
            '${month.year.toString().padLeft(4, '0')}-'
            '${month.month.toString().padLeft(2, '0')}',
      },
    );
    return _asMapList(response.data);
  }

  static Future<List<Map<String, dynamic>>> getTeacherAttendance({
    DateTime? date,
  }) async {
    final response = await _dio.get(
      '/api/scolarite/teacher-attendance',
      queryParameters: {
        if (date != null) 'date': date.toIso8601String().substring(0, 10),
      },
    );
    return _asMapList(response.data);
  }

  static Future<void> saveTeacherAttendance({
    required String teacherId,
    required String status,
    DateTime? date,
  }) async {
    await _dio.post(
      '/api/scolarite/teacher-attendance',
      data: {
        'teacherId': int.tryParse(teacherId) ?? teacherId,
        'status': status,
        'attendanceDate': (date ?? DateTime.now()).toIso8601String().substring(
          0,
          10,
        ),
      },
    );
  }

  static Future<void> justifyTeacherRoomAbsence(
    String checkId,
    String userId,
    String justification,
  ) async {
    await _dio.put(
      '/api/academique/teacher-room-checks/$checkId/justification',
      data: {'userId': userId, 'justification': justification},
    );
  }

  // --- PROGRAMME ---

  static Future<List<Map<String, dynamic>>> getProgramChapters({
    String? teacherId,
    String? className,
    bool? completed,
  }) async {
    final response = await _dio.get(
      '/api/academique/program',
      queryParameters: {
        if (teacherId != null) 'teacherId': teacherId,
        if (className != null) 'className': className,
        if (completed != null) 'completed': completed,
      },
    );
    return _asMapList(response.data);
  }

  static Future<void> saveProgramChapter(Map<String, dynamic> data) async {
    await _dio.post('/api/academique/program', data: data);
  }

  static Future<void> setProgramChapterCompleted(
    String id,
    bool completed,
  ) async {
    await _dio.put(
      '/api/academique/program/$id/completed',
      queryParameters: {'completed': completed},
    );
  }

  // --- FINANCE ---

  static Future<List<Payment>> getPayments() async {
    final response = await _dio.get('/api/finance/payments');
    return _asMapList(response.data).map(Payment.fromMap).toList();
  }

  static Future<List<Payment>> getParentPayments(String parentUserId) async {
    final response = await _dio.get(
      '/api/finance/parents/$parentUserId/payments',
    );
    return _asMapList(response.data).map(Payment.fromMap).toList();
  }

  static Future<Payment> savePayment(Payment payment) async {
    final data = payment.toMap();
    if (payment.id.isEmpty || payment.id == '0') data.remove('id');
    final response = await _dio.post('/api/finance/payments', data: data);
    return Payment.fromMap(_asMap(response.data));
  }

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    final response = await _dio.get('/api/finance/expenses');
    return _asMapList(response.data);
  }

  static Future<void> saveExpense(Map<String, dynamic> expense) async {
    final data = Map<String, dynamic>.from(expense);
    if (data['id'] == null ||
        data['id'].toString().isEmpty ||
        data['id'].toString() == '0')
      data.remove('id');
    await _dio.post('/api/finance/expenses', data: data);
  }

  static Future<void> deleteExpense(String id) async {
    await _dio.delete('/api/finance/expenses/$id');
  }

  static Future<Map<String, dynamic>> getFinanceStats() async {
    final response = await _dio.get('/api/finance/stats');
    return _asMap(response.data);
  }

  static Future<List<Map<String, dynamic>>> getTuitionStatus() async {
    final response = await _dio.get('/api/finance/tuition-status');
    return _asMapList(response.data);
  }

  static Future<bool> deletePayment(String paymentId) async {
    try {
      await _dio.delete('/api/finance/payments/$paymentId');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- DISCIPLINE ---

  static Future<List<Absence>> getAbsences({String? className}) async {
    final response = await _dio.get(
      '/api/discipline/absences',
      queryParameters: {
        if (className != null && className != 'Toutes') 'className': className,
      },
    );
    return _asMapList(response.data).map(Absence.fromMap).toList();
  }

  static Future<void> saveAbsence(Absence absence) async {
    final data = absence.toMap();
    if (absence.id.isEmpty || absence.id == '0') data.remove('id');
    await _dio.post('/api/discipline/absences', data: data);
  }

  static Future<List<Sanction>> getSanctions() async {
    final response = await _dio.get('/api/discipline/sanctions');
    return _asMapList(response.data).map(Sanction.fromMap).toList();
  }

  static Future<void> addSanction(Sanction sanction) async {
    final data = sanction.toMap();
    if (sanction.id.isEmpty || sanction.id == '0') data.remove('id');
    await _dio.post('/api/discipline/sanctions', data: data);
  }

  static Future<void> deleteSanction(String id) async {
    await _dio.delete('/api/discipline/sanctions/$id');
  }

  // --- ÉCOLE & ANNÉES ACADÉMIQUES ---

  static Future<SchoolInfo?> getSchoolInfo() async {
    final response = await _dio.get('/api/school/info');
    if (response.data == null) return null;
    return SchoolInfo.fromMap(_asMap(response.data));
  }

  static Future<SchoolInfo> updateSchoolInfo(SchoolInfo info) async {
    final response = await _dio.put('/api/school/info', data: info.toMap());
    return SchoolInfo.fromMap(_asMap(response.data));
  }

  static Future<List<AcademicYearRecap>> getAcademicYears() async {
    final response = await _dio.get('/api/school/years');
    return _asMapList(response.data).map(AcademicYearRecap.fromMap).toList();
  }

  static Future<List<AcademicYearRecap>> getPastYearRecaps() async {
    final response = await _dio.get('/api/school/years/recaps');
    return _asMapList(response.data).map(AcademicYearRecap.fromMap).toList();
  }

  static Future<Set<String>> getAcademicYearArchives({
    required int yearId,
  }) async {
    final response = await _dio.get('/api/school/years/$yearId/archives');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Format de liste des archives invalide.');
    }
    return data
        .map((entry) {
          if (entry is String) return entry;
          if (entry is Map) {
            return entry['type']?.toString() ?? entry['name']?.toString() ?? '';
          }
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  static Future<void> uploadAcademicYearArchive({
    required int yearId,
    required String type,
    required Uint8List bytes,
  }) async {
    await _dio.put(
      '/api/school/years/$yearId/archives/$type',
      data: bytes,
      options: Options(contentType: 'application/pdf'),
    );
  }

  static Future<Uint8List> exportCompressedAcademicYearBackup(
    int yearId,
  ) async {
    final response = await _dio.get<List<int>>(
      '/api/backup/export-year/$yearId/archive',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null ||
        bytes.length < 2 ||
        bytes[0] != 0x1f ||
        bytes[1] != 0x8b) {
      throw const FormatException(
        'La sauvegarde compressée de l’école est invalide.',
      );
    }
    return Uint8List.fromList(bytes);
  }

  static Future<void> uploadCompressedAcademicYearArchive({
    required int yearId,
    required Uint8List bytes,
  }) async {
    await _dio.put(
      '/api/school/years/$yearId/archives/year_data',
      data: bytes,
      options: Options(contentType: 'application/gzip'),
    );
  }

  static Future<Uint8List> downloadAcademicYearArchive({
    required int yearId,
    required String type,
  }) async {
    final response = await _dio.get<List<int>>(
      '/api/school/years/$yearId/archives/$type',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const FormatException('Le fichier PDF archivé est vide.');
    }
    return Uint8List.fromList(data);
  }

  static Future<void> finalizeAcademicYearArchive(int yearId) async {
    await _dio.post('/api/school/years/$yearId/archives/finalize');
  }

  static Future<AcademicYearRecap> startNewAcademicYear({
    required String label,
    DateTime? startDate,
    required DateTime archiveDate,
  }) async {
    final response = await _dio.post(
      '/api/school/years',
      data: {
        'label': label,
        if (startDate != null)
          'startDate': startDate.toIso8601String().substring(0, 10),
        'archiveDate': archiveDate.toIso8601String().substring(0, 10),
      },
    );
    return AcademicYearRecap.fromMap(_asMap(response.data));
  }

  static Future<AcademicYearRecap> closeCurrentAcademicYear() async {
    final response = await _dio.post('/api/school/years/close');
    return AcademicYearRecap.fromMap(_asMap(response.data));
  }

  static Future<SchoolInfo?> renewSubscription({
    required String schoolId,
    required String actorId,
    required int months,
    required double amount,
    required String paymentMethod,
    String? transactionRef,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/api/schools/$schoolId/subscription/renew',
      queryParameters: {'actorId': actorId},
      data: {
        'months': months,
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (transactionRef != null) 'transactionRef': transactionRef,
        if (notes != null) 'notes': notes,
      },
    );
    return SchoolInfo.fromMap(_asMap(response.data));
  }

  // --- NOTIFICATIONS & DIVERS ---

  static Future<List<Map<String, dynamic>>> getUnreadNotifications({
    String? userId,
  }) async {
    final response = await _dio.get(
      '/api/notifications/unread',
      queryParameters: {if (userId != null) 'userId': userId},
    );
    return _asMapList(response.data);
  }

  static Future<void> markNotificationRead(String id, {String? userId}) async {
    await _dio.put(
      '/api/notifications/$id/read',
      queryParameters: {if (userId != null) 'userId': userId},
    );
  }

  static Future<void> registerPushToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/api/notifications/devices',
      data: {'token': token, 'platform': platform},
    );
  }

  static Future<Map<String, dynamic>> getSaasSettings() async {
    final response = await _dio.get('/api/saas-settings');
    return _asMap(response.data);
  }

  static Future<BulletinPublication?> getBulletinPublicationStatus({
    required String className,
    required String period,
    String? studentId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/academique/bulletin-publications/check',
        queryParameters: {
          'className': className,
          'period': period,
          if (studentId != null) 'studentId': studentId,
        },
      );
      final data = _asMap(response.data);
      if (data['published'] == true && data['publication'] != null)
        return BulletinPublication.fromMap(_asMap(data['publication']));
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<BulletinPublication>> getBulletinPublications({
    String? className,
    String? period,
    String? studentId,
  }) async {
    final response = await _dio.get(
      '/api/academique/bulletin-publications',
      queryParameters: {
        if (className != null) 'className': className,
        if (period != null) 'period': period,
        if (studentId != null) 'studentId': studentId,
      },
    );
    return _asMapList(response.data).map(BulletinPublication.fromMap).toList();
  }

  static Future<Map<String, dynamic>> getBulletinReadiness({
    required String className,
    String? period,
    String? studentId,
  }) async {
    final response = await _dio.get(
      '/api/academique/bulletin-publications/readiness',
      queryParameters: {
        'className': className,
        if (period != null) 'period': period,
        if (studentId != null) 'studentId': studentId,
      },
    );
    return _asMap(response.data);
  }

  static Future<BulletinPublication> publishBulletin({
    required String className,
    required String period,
    required String languageCode,
    String? studentId,
    required String publishedBy,
    required String publishedByRole,
  }) async {
    final response = await _dio.post(
      '/api/academique/bulletin-publications/publish',
      data: {
        'className': className,
        'period': period,
        'languageCode': languageCode,
        if (studentId != null) 'studentId': studentId,
        'publishedBy': publishedBy,
        'publishedByRole': publishedByRole,
      },
    );
    return BulletinPublication.fromMap(_asMap(response.data));
  }

  static Future<BulletinPublication?> unpublishBulletin({
    required String className,
    required String period,
    String? studentId,
  }) async {
    final response = await _dio.post(
      '/api/academique/bulletin-publications/unpublish',
      data: {
        'className': className,
        'period': period,
        if (studentId != null) 'studentId': studentId,
      },
    );
    final data = _asMap(response.data);
    return data.isNotEmpty ? BulletinPublication.fromMap(data) : null;
  }

  static Future<List<AuditLog>> getAuditLogs({
    String? entityType,
    String? search,
  }) async {
    final response = await _dio.get(
      '/api/audit-logs',
      queryParameters: {
        if (entityType != null && entityType != 'TOUS')
          'entityType': entityType,
        if (search != null) 'search': search,
      },
    );
    return _asMapList(response.data).map(AuditLog.fromMap).toList();
  }

  static Future<List<Map<String, dynamic>>> getPendingSubmissions({
    String? period,
  }) async {
    final response = await _dio.get(
      '/api/academique/pending-submissions',
      queryParameters: {if (period != null) 'period': period},
    );
    return _asMapList(response.data);
  }

  static Future<bool> remindPayment({
    required String studentId,
    required String studentName,
    required double amount,
    String? reason,
  }) async {
    try {
      await _dio.post(
        '/api/notifications/remind-payment',
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'amount': amount,
          if (reason != null) 'reason': reason,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> broadcastAnnouncement({
    required String title,
    required String message,
    String audience = 'TOUS',
  }) async {
    try {
      await _dio.post(
        '/api/notifications/announcement',
        data: {'title': title, 'message': message, 'audience': audience},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> exportBackup() async {
    final response = await _dio.get('/api/backup/export');
    return _asMap(response.data);
  }

  static Future<Map<String, dynamic>> importBackup(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/backup/import', data: data);
    return _asMap(response.data);
  }

  static Future<Map<String, dynamic>> getBackupStatus() async {
    try {
      final response = await _dio.get('/api/backup/status');
      return _asMap(response.data);
    } catch (_) {
      return {
        'autoBackupEnabled': true,
        'schedule': 'Quotidien automatique (02h00)',
        'status': 'Opérationnel',
      };
    }
  }

  static Future<Map<String, dynamic>> getDashboardInsights({
    String? period,
  }) async {
    final response = await _dio.get(
      '/api/dashboard/insights',
      queryParameters: {if (period != null) 'period': period},
    );
    return _asMap(response.data);
  }

  static Future<bool> deleteLesson(String lessonId) async {
    try {
      await _dio.delete('/api/academique/lessons/$lessonId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
