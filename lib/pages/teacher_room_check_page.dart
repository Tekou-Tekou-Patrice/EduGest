import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/schedule.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeacherRoomCheckPage extends StatefulWidget {
  final AppUser currentUser;
  const TeacherRoomCheckPage({super.key, required this.currentUser});

  @override
  State<TeacherRoomCheckPage> createState() => _TeacherRoomCheckPageState();
}

class _TeacherRoomCheckPageState extends State<TeacherRoomCheckPage> {
  List<ScheduleItem> _schedule = [];
  Map<String, Map<String, dynamic>> _checks = {};
  bool _loading = true;
  final DateTime _date = DateTime.now();

  bool get _isTeacher => widget.currentUser.role == UserRole.enseignant;
  bool get _isSecretary => widget.currentUser.role == UserRole.secretaire;
  bool get _canVerify =>
      widget.currentUser.role == UserRole.surveillantGeneral ||
      widget.currentUser.role == UserRole.surveillant;

  String get _day {
    const days = [
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
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
        SnackBar(content: Text('Impossible de charger les cours : $error')),
      );
    }
  }

  bool _isStillCheckable(ScheduleItem item) {
    final end = item.endTime.split(':');
    if (end.length != 2) return true;
    final endMinutes =
        (int.tryParse(end[0]) ?? 0) * 60 + (int.tryParse(end[1]) ?? 0);
    final now = DateTime.now();
    return now.hour * 60 + now.minute <= endMinutes;
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
        SnackBar(content: Text('Enregistrement impossible : $error')),
      );
    }
  }

  Future<void> _justify(Map<String, dynamic> check) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Justifier mon absence'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Explication',
              hintText: 'Expliquez votre absence...',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'L’explication est obligatoire'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
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
                      content: Text('Justification impossible : $error'),
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (submitted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _checks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Présence des professeurs en salle',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
            ),
          ],
        ),
        Text(
          _isTeacher
              ? 'Vos absences signalées et leur délai de justification'
              : '${DateFormat('dd/MM/yyyy').format(_date)} — $_day — $checkedCount/${_schedule.length} cours vérifiés',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_isTeacher && _checks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucune absence à justifier.')),
            ),
          )
        else if (!_isTeacher && _schedule.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucun cours prévu aujourd’hui.')),
            ),
          )
        else if (_isTeacher)
          ..._checks.values.map(_buildTeacherAbsenceCard)
        else
          ..._schedule.map(_buildCourseCard),
      ],
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text('${check['subject'] ?? ''} — ${check['className'] ?? ''}'),
        subtitle: Text(
          'Absence signalée le ${check['checkDate'] ?? ''}'
          '${canJustify ? '\nJustification avant le $deadlineText' : ''}'
          '${check['justification'] != null ? '\nJustification envoyée' : ''}',
        ),
        isThreeLine: true,
        trailing: canJustify
            ? TextButton(
                onPressed: () => _justify(check),
                child: const Text('Justifier'),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.startTime} - ${item.endTime} • ${item.subject}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.teacherName} — ${item.className}'
              '${item.room.isEmpty ? '' : ' — Salle ${item.room}'}',
            ),
            if (hasCheck)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${present ? 'Présent' : 'Absent'} — vérifié à ${_formatCheckedAt(check['checkedAt'])} par ${check['verifierName'] ?? ''}',
                  style: TextStyle(
                    color: present
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_canVerify) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _mark(item, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Présent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _mark(item, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Absent'),
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
