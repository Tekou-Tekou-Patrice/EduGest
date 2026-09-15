import 'dart:async';

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'package:dio/dio.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../models/schedule.dart';
import '../models/absence.dart';
import '../service/api_service.dart';

class AppelPage extends StatefulWidget {
  final AppUser currentUser;
  const AppelPage({super.key, required this.currentUser});

  @override
  State<AppelPage> createState() => _AppelPageState();
}

class _AppelPageState extends State<AppelPage> with WidgetsBindingObserver {
  ScheduleItem? _currentSession;
  List<Student> _eleves = [];
  Map<String, bool> _presenceMap = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchCurrentSessionAndStudents();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchCurrentSessionAndStudents(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCurrentSessionAndStudents();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchCurrentSessionAndStudents() async {
    if (!mounted) return;
    if (widget.currentUser.role != UserRole.enseignant) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      debugPrint(
        "AppelPage: Recherche de session pour ${widget.currentUser.name}",
      );

      // 1. Trouver le cours actuel
      final session = await ApiService.getCurrentSession(
        widget.currentUser.name,
      );

      if (session != null) {
        debugPrint(
          "AppelPage: Session trouvée -> ${session.subject} (Classe: ${session.className})",
        );

        // 2. Récupérer les élèves de la classe
        // On nettoie le nom de la classe (trim) pour éviter les erreurs d'espaces
        final students = await ApiService.getStudents(
          className: session.className.trim(),
        );
        debugPrint(
          "AppelPage: ${students.length} élèves trouvés pour la classe ${session.className}",
        );

        if (mounted) {
          setState(() {
            _currentSession = session;
            _eleves = students;
            // Par défaut tout le monde est présent (true)
            _presenceMap = {for (var s in students) s.id: true};
            _isLoading = false;
          });
        }
      } else {
        debugPrint("AppelPage: Aucune session trouvée pour l'heure actuelle.");
        if (mounted) {
          setState(() {
            _currentSession = null;
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      debugPrint("AppelPage Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
        );
      }
    } catch (e) {
      debugPrint("AppelPage Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _envoyerAppel() async {
    if (_currentSession == null || _eleves.isEmpty) return;

    setState(() => _isLoading = true);
    int absentCount = 0;

    try {
      for (var student in _eleves) {
        bool isPresent = _presenceMap[student.id] ?? true;
        if (!isPresent) {
          absentCount++;
          await ApiService.saveAbsence(
            Absence(
              id: '',
              studentId: student.id,
              studentName: student.fullName,
              className: _currentSession!.className,
              date: DateTime.now(),
              period:
                  "${_currentSession!.startTime} - ${_currentSession!.endTime}",
              reason: "Absence signalée par ${widget.currentUser.name}",
              isJustified: false,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('attendanceCompleted')),
            content: Text(
              "${context.tr('attendanceSent')}\n${context.tr('absentCount')}: $absentCount",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.friendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.currentUser.role != UserRole.enseignant) {
      return Center(
        child: Text(
          context.tr('teachersOnlyAttendance'),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Cas 1 : Pas de session en cours
    if (_currentSession == null) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.event_busy, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 20),
            Text(
              context.tr('noClassAtTime'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('checkTimetableClock'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchCurrentSessionAndStudents,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('refresh')),
            ),
          ],
        ),
      );
    }

    // Cas 2 : Session trouvée
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du cours
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentSession!.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_currentSession!.startTime} - ${_currentSession!.endTime}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "${context.tr('classLabel')} : ${_currentSession!.className}",
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        if (_eleves.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Icon(Icons.group_off, color: Colors.redAccent, size: 40),
                const SizedBox(height: 15),
                Text(
                  "${context.tr('noStudentsInClassPrefix')} \"${_currentSession!.className}\".",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('checkClassNameAttendance'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _fetchCurrentSessionAndStudents,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          )
        else ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                "${context.tr('attendanceList')} (${_eleves.length} ${context.tr('students').toLowerCase()})",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(
                  () => _presenceMap = {for (var s in _eleves) s.id: true},
                ),
                icon: const Icon(Icons.done_all),
                label: Text(context.tr('allPresent')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eleves.length,
            itemBuilder: (context, index) {
              final student = _eleves[index];
              bool isPresent = _presenceMap[student.id] ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPresent ? AppColors.border : Colors.red.shade200,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    student.fullName,
                    style: TextStyle(
                      fontWeight: isPresent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isPresent ? AppColors.text : Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    isPresent ? context.tr('present') : context.tr('absent'),
                    style: TextStyle(
                      color: isPresent ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  value: isPresent,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _presenceMap[student.id] = val ?? true;
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: MyButton(
              text: "Valider l'appel",
              icon: Icons.send,
              onTap: _envoyerAppel,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }
}
