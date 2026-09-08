import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/models/schedule.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/models/teacher.dart';
import 'package:edugest/models/subject.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';

class EmploiDuTemps extends StatefulWidget {
  final AppUser currentUser;
  const EmploiDuTemps({super.key, required this.currentUser});

  @override
  State<EmploiDuTemps> createState() => _EmploiDuTempsState();
}

class _EmploiDuTempsState extends State<EmploiDuTemps> {
  String selectedDay = 'Lundi';
  List<ScheduleItem> _scheduleItems = [];
  List<SchoolClass> _allClasses = [];
  List<Teacher> _allTeachers = [];
  List<Subject> _allSubjects = [];
  bool _isLoading = true;

  final List<String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchSchedule(),
      _fetchClassesProfsAndSubjects(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchClassesProfsAndSubjects() async {
    try {
      final results = await Future.wait([
        ApiService.getClassrooms(),
        ApiService.getTeachers(),
        ApiService.getSubjects(),
      ]);
      if (mounted) {
        setState(() {
          _allClasses = results[0] as List<SchoolClass>;
          _allTeachers = results[1] as List<Teacher>;
          _allSubjects = results[2] as List<Subject>;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement données: $e");
    }
  }

  Future<void> _fetchSchedule() async {
    try {
      final role = widget.currentUser.displayRole;
      List<ScheduleItem> data;

      if (role == 'Enseignant') {
        data = await ApiService.getSchedule(day: selectedDay, teacherName: widget.currentUser.name);
      } else {
        data = await ApiService.getSchedule(day: selectedDay);
      }

      if (mounted) {
        setState(() {
          _scheduleItems = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la récupération de l'emploi du temps")),
        );
      }
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  void _showAddScheduleDialog() {
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    
    String? currentClass = _allClasses.isNotEmpty ? _allClasses.first.name : null;
    String? currentTeacher = widget.currentUser.displayRole == 'Enseignant' 
        ? widget.currentUser.name 
        : (_allTeachers.isNotEmpty ? _allTeachers.first.fullName : null);
    String? currentSubject = _allSubjects.isNotEmpty ? _allSubjects.first.name : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ajouter un Créneau"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown Matière
                DropdownButtonFormField<String>(
                  value: _allSubjects.any((s) => s.name == currentSubject) ? currentSubject : null,
                  decoration: InputDecoration(
                    labelText: "Matière",
                    prefixIcon: const Icon(Icons.book, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _allSubjects.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                  onChanged: (val) => setDialogState(() => currentSubject = val),
                ),
                const SizedBox(height: 12),
                
                // Dropdown Classe
                DropdownButtonFormField<String>(
                  value: _allClasses.any((c) => c.name == currentClass) ? currentClass : null,
                  decoration: InputDecoration(
                    labelText: "Classe",
                    prefixIcon: const Icon(Icons.school, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _allClasses.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                  onChanged: (val) => setDialogState(() => currentClass = val),
                ),
                const SizedBox(height: 12),

                // Dropdown Enseignant
                DropdownButtonFormField<String>(
                  value: _allTeachers.any((t) => t.fullName == currentTeacher) ? currentTeacher : null,
                  decoration: InputDecoration(
                    labelText: "Enseignant",
                    prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _allTeachers.map((t) => DropdownMenuItem(value: t.fullName, child: Text(t.fullName))).toList(),
                  onChanged: (val) => setDialogState(() => currentTeacher = val),
                ),
                const SizedBox(height: 16),

                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await _selectTime(context, startTime);
                          if (picked != null) setDialogState(() => startTime = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Début",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_formatTimeOfDay(startTime)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await _selectTime(context, endTime);
                          if (picked != null) setDialogState(() => endTime = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Fin",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_formatTimeOfDay(endTime)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (currentSubject == null || currentClass == null || currentTeacher == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Champs manquants")));
                  return;
                }
                final newItem = ScheduleItem(
                  id: '',
                  day: selectedDay,
                  subject: currentSubject!,
                  className: currentClass!,
                  teacherName: currentTeacher!,
                  room: '', // Champ retiré selon demande
                  startTime: _formatTimeOfDay(startTime),
                  endTime: _formatTimeOfDay(endTime),
                );
                await ApiService.saveScheduleItem(newItem);
                if (mounted) Navigator.pop(context);
                _fetchSchedule();
              },
              child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const Text(
              "Planning Hebdomadaire",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.currentUser.displayRole != 'Enseignant')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _showAddScheduleDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text("Ajouter Créneau", style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _loadAllData,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sélecteur de jour
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) {
              final isSelected = selectedDay == day;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedDay = day);
                  _fetchSchedule();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_scheduleItems.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucun cours programmé pour ce jour.")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scheduleItems.length,
            itemBuilder: (context, index) {
              final item = _scheduleItems[index];
              return IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                          Text(item.endTime, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const VerticalDivider(thickness: 2, color: AppColors.border),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isBreak ? Colors.grey.shade100 : AppColors.primaryPale.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: item.isBreak ? Colors.grey.shade300 : AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subject,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: item.isBreak ? Colors.grey.shade600 : AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (!item.isBreak) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "${item.className} • ${item.teacherName}",
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.currentUser.displayRole != 'Enseignant')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await ApiService.deleteScheduleItem(item.id);
                                  _fetchSchedule();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
