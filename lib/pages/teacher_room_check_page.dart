import 'dart:async';

import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/schedule.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/school_notifier.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:intl/intl.dart';

class TeacherRoomCheckPage extends StatefulWidget {
  final AppUser currentUser;
  const TeacherRoomCheckPage({super.key, required this.currentUser});

  @override
  State<TeacherRoomCheckPage> createState() => _TeacherRoomCheckPageState();
}

class _TeacherRoomCheckPageState extends State<TeacherRoomCheckPage> {
  List<ScheduleItem> _schedule = [];
  List<Map<String, dynamic>> _teacherAttendance = [];
  Map<String, Map<String, dynamic>> _checks = {};
  bool _loading = true;
  final DateTime _date = DateTime.now();
  Timer? _scheduleRefreshTimer;

  bool get _isTeacher => widget.currentUser.role == UserRole.enseignant;
  bool get _isSecretary => widget.currentUser.role == UserRole.secretaire;
  bool get _isPrimaryAdmin =>
      (widget.currentUser.role == UserRole.proviseur ||
          widget.currentUser.role == UserRole.secretaire ||
          widget.currentUser.role == UserRole.fondateur) &&
      currentSchoolNotifier.value?.schoolLevel == 'PRIMARY';
  bool get _canVerify =>
      widget.currentUser.role == UserRole.fondateur ||
      widget.currentUser.role == UserRole.proviseur ||
      widget.currentUser.role == UserRole.surveillantGeneral ||
      widget.currentUser.role == UserRole.surveillant;

  String get _day {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[_date.weekday - 1];
  }

  String _localizedDay(BuildContext context) {
    const dayKeys = [
      'weekdayMonday',
      'weekdayTuesday',
      'weekdayWednesday',
      'weekdayThursday',
      'weekdayFriday',
      'weekdaySaturday',
      'weekdaySunday',
    ];
    return context.tr(dayKeys[_date.weekday - 1]);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _scheduleRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _load(showLoading: false),
    );
  }

  @override
  void dispose() {
    _scheduleRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      if (_isPrimaryAdmin) {
        final attendance = await ApiService.getTeacherAttendance(date: _date);
        if (!mounted) return;
        setState(() {
          _teacherAttendance = attendance;
          _loading = false;
        });
        return;
      }
      final results = await Future.wait([
        _isTeacher
            ? Future.value(<ScheduleItem>[])
            : ApiService.getSchedule(day: _day),
        _isTeacher
            ? ApiService.getTeacherRoomChecks(teacherId: widget.currentUser.id)
            : ApiService.getTeacherRoomChecks(date: _date),
      ]);
      final schedules = results[0] as List<ScheduleItem>;
      final checks = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _schedule = schedules
            .where(
              (item) =>
                  !item.isBreak && (_isSecretary || _isStillCheckable(item)),
            )
            .toList();
        _checks = {
          for (final check in checks) check['scheduleItemId'].toString(): check,
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('loadClassesError')}: '
            '${ApiService.friendlyErrorMessage(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _markTeacherAttendance(
    Map<String, dynamic> teacher,
    String status,
  ) async {
    try {
      await ApiService.saveTeacherAttendance(
        teacherId: teacher['teacherId'].toString(),
        status: status,
        date: _date,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('saveFailed')}: '
            '${ApiService.friendlyErrorMessage(error)}',
          ),
        ),
      );
    }
  }

  bool _isStillCheckable(ScheduleItem item) {
    final startMinutes = _minutesSinceMidnight(item.startTime);
    final endMinutes = _minutesSinceMidnight(item.endTime);
    if (startMinutes == null || endMinutes == null) return false;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  int? _minutesSinceMidnight(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  Future<void> _mark(ScheduleItem item, bool present) async {
    if (!_canVerify) return;
    try {
      await ApiService.saveTeacherRoomCheck({
        'scheduleItemId': int.tryParse(item.id) ?? item.id,
        'checkDate': DateFormat('yyyy-MM-dd').format(_date),
        'present': present,
        'teacherName': item.teacherName,
        'className': item.className,
        'subject': item.subject,
        'room': item.room,
        'verifierId': widget.currentUser.id,
        'verifierName': widget.currentUser.name,
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('saveFailed')}: '
            '${ApiService.friendlyErrorMessage(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _justify(Map<String, dynamic> check) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('justifyMyAbsence')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: context.tr('explanation'),
              hintText: context.tr('explainAbsence'),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? context.tr('explanationRequired')
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.justifyTeacherRoomAbsence(
                  check['id'].toString(),
                  widget.currentUser.id,
                  controller.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${dialogContext.tr('saveFailed')}: '
                        '${ApiService.friendlyErrorMessage(error)}',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(context.tr('send')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (submitted == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _schedule
        .where((item) => _checks.containsKey(item.id))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('teacherRoomPresence'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: Icon(Icons.refresh, color: AppColors.primary),
            ),
          ],
        ),
        Text(
          _isPrimaryAdmin
              ? '${DateFormat('dd/MM/yyyy').format(_date)} — ${context.tr('attendanceDayLabel')}'
              : _isTeacher
              ? context.tr('reportedAbsencesJustification')
              : '${DateFormat('dd/MM/yyyy').format(_date)} — ${_localizedDay(context)} — '
                    '$checkedCount/${_schedule.length} ${context.tr('lessonsVerified')}',
          style: TextStyle(color: AppColors.textMuted),
        ),
        SizedBox(height: 20),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_isPrimaryAdmin)
          ..._teacherAttendance.map(_buildTeacherAttendanceCard)
        else if (_isTeacher && _checks.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(context.tr('noAbsencesToJustify'))),
            ),
          )
        else if (!_isTeacher && _schedule.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text(context.tr('noClassAtTime'))),
            ),
          )
        else if (_isTeacher)
          ..._checks.values.map(_buildTeacherAbsenceCard)
        else
          ..._schedule.map(_buildCourseCard),
      ],
    );
  }

  Widget _buildTeacherAttendanceCard(Map<String, dynamic> teacher) {
    final status = teacher['status']?.toString() ?? 'UNMARKED';
    final labels = {
      'PRESENT': context.tr('status_present'),
      'ABSENT': context.tr('status_absent'),
      'LATE': context.tr('status_late'),
      'PERMISSION': context.tr('status_permission'),
      'UNMARKED': context.tr('status_unmarked'),
    };
    final colors = {
      'PRESENT': Colors.green,
      'ABSENT': Colors.red,
      'LATE': Colors.orange,
      'PERMISSION': Colors.blue,
      'UNMARKED': Colors.grey,
    };
    final color = colors[status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(Icons.person, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    teacher['teacherName']?.toString() ??
                        context.trRole(
                          'enseignant',
                          schoolLevel: currentSchoolNotifier.value?.schoolLevel,
                        ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(labels[status] ?? status),
                  labelStyle: TextStyle(color: color),
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _attendanceButton(
                  teacher,
                  'PRESENT',
                  context.tr('status_present'),
                  Colors.green,
                ),
                _attendanceButton(
                  teacher,
                  'ABSENT',
                  context.tr('status_absent'),
                  Colors.red,
                ),
                _attendanceButton(
                  teacher,
                  'LATE',
                  context.tr('status_late'),
                  Colors.orange,
                ),
                _attendanceButton(
                  teacher,
                  'PERMISSION',
                  context.tr('status_permission'),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceButton(
    Map<String, dynamic> teacher,
    String status,
    String label,
    Color color,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _markTeacherAttendance(teacher, status),
      icon: Icon(Icons.circle, size: 10, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(foregroundColor: color),
    );
  }

  Widget _buildTeacherAbsenceCard(Map<String, dynamic> check) {
    final deadline = DateTime.tryParse(
      check['justificationDeadline']?.toString() ?? '',
    );
    final canJustify =
        check['justification'] == null &&
        deadline != null &&
        DateTime.now().isBefore(deadline);
    final deadlineText = deadline == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(deadline);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.warning, color: Colors.red),
        title: Text('${check['subject']} — ${check['className']}'),
        subtitle: Text(
          '${context.tr('absenceReportedOn')} ${check['checkDate']}'
          '${canJustify ? '\n${context.tr('justificationBefore')} $deadlineText' : ''}'
          '${check['justification'] != null ? '\n${context.tr('justificationSent')}' : ''}',
        ),
        isThreeLine: true,
        trailing: canJustify
            ? TextButton(
                onPressed: () => _justify(check),
                child: Text(context.tr('justify')),
              )
            : null,
      ),
    );
  }

  Widget _buildCourseCard(ScheduleItem item) {
    final check = _checks[item.id];
    final hasCheck = check != null;
    final present = check?['present'] == true;
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasCheck
                      ? (present ? Icons.check_circle : Icons.cancel)
                      : Icons.help_outline,
                  color: hasCheck
                      ? (present ? Colors.green : Colors.red)
                      : Colors.orange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.startTime} - ${item.endTime} • ${item.subject}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${item.teacherName} — ${item.className}'
              '${item.room.isEmpty ? '' : ' — ${context.tr('room')} ${item.room}'}',
            ),
            if (hasCheck)
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  '${present ? context.tr('present') : context.tr('absent')} — '
                  '${context.tr('verifiedAt')} ${_formatCheckedAt(check['checkedAt'])} '
                  '${context.tr('by')} ${check['verifierName']}',
                  style: TextStyle(
                    color: present
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_canVerify) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _mark(item, true),
                      icon: Icon(Icons.check),
                      label: Text(context.tr('present')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _mark(item, false),
                      icon: Icon(Icons.close),
                      label: Text(context.tr('auto_absent')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCheckedAt(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '--:--' : DateFormat('HH:mm').format(date);
  }
}
