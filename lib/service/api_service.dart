import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/student.dart';
import 'package:edugest/models/teacher.dart';
import 'package:edugest/models/payment.dart';
import 'package:edugest/models/absence.dart';
import 'package:edugest/models/sanction.dart';
import 'package:edugest/models/schedule.dart';
import 'package:edugest/models/event.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/models/school_info.dart';
import 'package:edugest/models/grade.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/models/academic_year_recap.dart';
import 'package:edugest/models/school.dart';

/// Client HTTP centralisé connecté exclusivement au backend Spring Boot.
class ApiService {
  ApiService._();

  // ⚠️ IMPORTANT :
  // - Émulateur Android  -> 10.0.2.2 (alias spécial vers localhost de la machine hôte)
  // - Téléphone réel (USB + `adb reverse tcp:8003 tcp:8003`) -> localhost fonctionne directement
  // - Web / Desktop -> localhost
  //
  // Comme on ne peut pas deviner automatiquement "émulateur" vs "vrai téléphone" sur Android,
  // bascule ce booléen manuellement selon ton support de test actuel.
  static const bool _usingRealDevice =
      true; // <- remets à false si tu reviens sur l'émulateur

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8003';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _usingRealDevice
          ? 'http://localhost:8003'
          : 'http://10.0.2.2:8003';
    }
    return 'http://localhost:8003';
  }

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final path = options.path;
              final isPublic =
                  path == '/api/users/login' ||
                  path == '/api/users/register' ||
                  path.startsWith('/api/schools/user/');
              if (!isPublic && activeSchoolId != null) {
                options.queryParameters['schoolId'] = activeSchoolId;
                options.headers['X-School-Id'] = activeSchoolId;
              }
              handler.next(options);
            },
          ),
        );
  static String? activeSchoolId;

  static void setActiveSchool(String schoolId) {
    activeSchoolId = schoolId;
  }

  static String _errorMessage(
    DioException e, [
    String fallback = 'Erreur réseau',
  ]) {
    final data = e.response?.data;
    debugPrint(
      'API ERROR ${e.requestOptions.method} ${e.requestOptions.uri} '
      'status=${e.response?.statusCode} type=${e.type} data=$data',
    );
    if (data is Map && data['message'] != null)
      return data['message'].toString();
    if (data is String && data.isNotEmpty) return data;

    // Si aucune réponse n'a été reçue du serveur (timeout, connexion refusée,
    // hôte injoignable...), ce n'est PAS un problème d'identifiants : on le
    // signale clairement plutôt que d'afficher le message par défaut trompeur.
    if (e.response == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Délai dépassé : le serveur ne répond pas (vérifie que le backend tourne et est joignable)';
        case DioExceptionType.connectionError:
          return 'Connexion au serveur impossible (vérifie l\'URL backend et le réseau)';
        default:
          return 'Erreur réseau : ${e.message ?? "impossible de joindre le serveur"}';
      }
    }

    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);

  static List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => _asMap(e)).toList();
  }

  // --- AUTH & STAFF ---

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      activeSchoolId = null;
      final response = await _dio.post(
        '/api/users/login',
        data: {'username': email, 'password': password},
      );
      return {'success': true, 'user': AppUser.fromMap(_asMap(response.data))};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _errorMessage(e, 'Identifiants incorrects'),
      };
    }
  }

  static Future<Map<String, dynamic>> registerAccount({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      await _dio.post(
        '/api/users/register',
        data: {
          'username': email,
          'email': email,
          'password': password,
          'fullName': name,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

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

  static Future<void> joinSchoolByCode({
    required String userId,
    required String code,
  }) async {
    try {
      await _dio.post(
        '/api/schools/join',
        queryParameters: {'userId': userId, 'code': code.trim()},
      );
    } on DioException catch (e) {
      debugPrint('JOIN SCHOOL FAILED codeLength=${code.trim().length}');
      throw _errorMessage(e, "Code d'établissement invalide");
    }
  }

  static Future<String> createSchool({
    required String userId,
    required String name,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/schools',
        data: {
          'name': name.trim(),
          'code': code.trim(),
          'userId': int.parse(userId),
        },
      );
      final data = _asMap(response.data);
      final schoolId = data['id']?.toString();
      if (schoolId == null || schoolId.isEmpty) {
        throw 'Identifiant de l’école absent dans la réponse du serveur';
      }
      return schoolId;
    } on DioException catch (e) {
      debugPrint(
        'CREATE SCHOOL FAILED name=$name codeLength=${code.trim().length}',
      );
      throw _errorMessage(e, "Impossible de créer l'établissement");
    }
  }

  static Future<void> updateSchoolCode({
    required String userId,
    required String schoolId,
    required String code,
  }) async {
    await _dio.put(
      '/api/schools/$schoolId/code',
      queryParameters: {'userId': int.parse(userId), 'code': code.trim()},
    );
  }

  static Future<Map<String, dynamic>> registerStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      await _dio.post(
        '/api/users/register',
        data: {
          'username': email,
          'email': email,
          'password': password,
          'fullName': name,
          'role': role,
          if (activeSchoolId != null) 'schoolId': int.tryParse(activeSchoolId!),
          if (phone != null) ...{'phone': phone},
        },
      );
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> registerFounder({
    required String name,
    required String email,
    required String password,
    required String schoolName,
    String? schoolCode,
    String? phone,
  }) async {
    try {
      await _dio.post(
        '/api/schools/register-founder',
        data: {
          'username': email,
          'email': email,
          'password': password,
          'fullName': name,
          'role': 'Fondateur',
          'schoolName': schoolName,
          if (schoolCode != null && schoolCode.trim().isNotEmpty)
            'schoolCode': schoolCode.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  static Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/users/$userId/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _errorMessage(e, 'Erreur lors du changement de mot de passe');
    }
  }

  static Future<List<AppUser>> getAllStaff() async {
    final response = await _dio.get('/api/users');
    return _asMapList(response.data).map(AppUser.fromMap).toList();
  }

  static Future<void> deleteUser(String id) async {
    await _dio.delete('/api/users/$id');
  }

  // --- SCOLARITÉ ---

  static Future<List<Student>> getStudents({
    String? className,
    String? query,
  }) async {
    final response = await _dio.get(
      '/api/scolarite/students',
      queryParameters: {
        if (className != null && className != 'Toutes') 'className': className,
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    return _asMapList(response.data).map(Student.fromMap).toList();
  }

  static Future<List<Student>> getParentStudents(String parentUserId) async {
    final response = await _dio.get(
      '/api/scolarite/parents/$parentUserId/students',
    );
    return _asMapList(response.data).map(Student.fromMap).toList();
  }

  static Future<void> saveStudent(Student student) async {
    final data = student.toMap();
    if (student.id.isEmpty || student.id == '0') data.remove('id');
    await _dio.post('/api/scolarite/students', data: data);
  }

  static Future<void> deleteStudent(String id) async {
    await _dio.delete('/api/scolarite/students/$id');
  }

  static Future<List<Teacher>> getTeachers({String? query}) async {
    final response = await _dio.get(
      '/api/scolarite/teachers',
      queryParameters: {if (query != null && query.isNotEmpty) 'query': query},
    );
    return _asMapList(response.data).map(Teacher.fromMap).toList();
  }

  static Future<void> saveTeacher(Teacher teacher) async {
    final data = teacher.toMap();
    if (teacher.id.isEmpty || teacher.id == '0') data.remove('id');
    await _dio.post('/api/scolarite/teachers', data: data);
  }

  static Future<void> deleteTeacher(String id) async {
    await _dio.delete('/api/scolarite/teachers/$id');
  }

  static Future<List<SchoolClass>> getClassrooms() async {
    final response = await _dio.get('/api/scolarite/classrooms');
    return _asMapList(response.data).map(SchoolClass.fromMap).toList();
  }

  static Future<void> saveClassroom(SchoolClass classroom) async {
    final data = classroom.toMap();
    if (classroom.id.isEmpty || classroom.id == '0') data.remove('id');
    await _dio.post('/api/scolarite/classrooms', data: data);
  }

  static Future<void> deleteClassroom(String id) async {
    await _dio.delete('/api/scolarite/classrooms/$id');
  }

  // --- ACADÉMIQUE ---

  static Future<List<ScheduleItem>> getSchedule({
    String? day,
    String? teacherName,
    String? className,
  }) async {
    final response = await _dio.get(
      '/api/academique/schedule',
      queryParameters: {
        if (day != null && day.isNotEmpty) 'day': day,
        if (teacherName != null && teacherName.isNotEmpty)
          'teacherName': teacherName,
        if (className != null && className.isNotEmpty) 'className': className,
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

  static Future<ScheduleItem?> getCurrentSession(String teacherName) async {
    final now = DateTime.now();
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final currentDay = days[now.weekday - 1];

    try {
      final schedule = await getSchedule(
        day: currentDay,
        teacherName: teacherName,
      );
      final currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      for (var item in schedule) {
        if (!item.isBreak &&
            currentTime.compareTo(item.startTime) >= 0 &&
            currentTime.compareTo(item.endTime) <= 0) {
          return item;
        }
      }
    } catch (e) {
      debugPrint("Erreur getCurrentSession: $e");
    }
    return null;
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

  static Future<List<Map<String, dynamic>>> getLessonsByClass(
    String className,
  ) async {
    final response = await _dio.get('/api/academique/lessons/class/$className');
    return _asMapList(response.data);
  }

  static Future<List<Map<String, dynamic>>> getAllLessons() async {
    final response = await _dio.get('/api/academique/lessons');
    return _asMapList(response.data);
  }

  static Future<void> saveLesson(Map<String, dynamic> lessonData) async {
    final data = Map<String, dynamic>.from(lessonData);
    if (data['id'] == null ||
        data['id'].toString().isEmpty ||
        data['id'].toString() == '0') {
      data.remove('id');
    }
    await _dio.post('/api/academique/lessons', data: data);
  }

  static Future<void> submitGrades(Map<String, dynamic> gradesData) async {
    await _dio.post('/api/academique/grades', data: gradesData);
  }

  static Future<List<Exam>> getExams({String? className}) async {
    final response = await _dio.get(
      '/api/academique/exams',
      queryParameters: {
        if (className != null && className.isNotEmpty) 'className': className,
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
        data['id'].toString() == '0') {
      data.remove('id');
    }
    await _dio.post('/api/finance/expenses', data: data);
  }

  static Future<void> deleteExpense(String id) async {
    await _dio.delete('/api/finance/expenses/$id');
  }

  static Future<Map<String, dynamic>> getFinanceStats() async {
    final response = await _dio.get('/api/finance/stats');
    return _asMap(response.data);
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

  // --- NOTIFICATIONS ---

  static Future<List<Map<String, dynamic>>> getUnreadNotifications({
    String? userId,
  }) async {
    final response = await _dio.get(
      '/api/notifications/unread',
      queryParameters: userId == null ? null : {'userId': userId},
    );
    return _asMapList(response.data);
  }

  static Future<void> markNotificationRead(String id, {String? userId}) async {
    await _dio.put(
      '/api/notifications/$id/read',
      queryParameters: userId == null ? null : {'userId': userId},
    );
  }
}
