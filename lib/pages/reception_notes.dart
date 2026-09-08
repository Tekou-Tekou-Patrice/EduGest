import 'package:flutter/material.dart';
import 'package:edugest/models/grade.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/export_service.dart';
import '../components/app_colors.dart';

class ReceptionNotes extends StatefulWidget {
  const ReceptionNotes({super.key});

  @override
  State<ReceptionNotes> createState() => _ReceptionNotesState();
}

class _ReceptionNotesState extends State<ReceptionNotes> {
  String selectedClasse = 'Toutes';
  List<Exam> _exams = [];
  bool _isLoading = true;

  final List<String> _classes = ['Toutes', '6eme', '5eme', '4eme', '3eme', '2nd', '1ere', 'Terminale'];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getExams(
        className: selectedClasse == 'Toutes' ? null : selectedClasse,
      );
      if (mounted) {
        setState(() {
          _exams = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
          runSpacing: 8,
          children: [
            const Text(
              "Réception & Validation des Notes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _fetchExams,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filtre de classe
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _classes.map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(c),
                  selected: selectedClasse == c,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedClasse = c);
                      _fetchExams();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 25),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_exams.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text("Aucune soumission d'examen trouvée pour cette classe."),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exams.length,
            itemBuilder: (context, index) {
              final exam = _exams[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(Icons.assignment_turned_in, color: AppColors.primary),
                  ),
                  title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Matière: ${exam.subject} • Classe: ${exam.className}"
                    "${exam.teacherName?.trim().isNotEmpty == true ? ' • Envoyé par ${exam.teacherName}' : ''}",
                  ),
                  isThreeLine: exam.teacherName?.trim().isNotEmpty == true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGradesTable(context, exam),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showGradesTable(BuildContext context, Exam exam) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final grades = await ApiService.getGradesByExam(exam.id);
      final students = await ApiService.getStudents(className: exam.className);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Remove loading

      final studentMap = {for (var s in students) s.id: s.fullName};

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Bordereau : ${exam.title}")),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => ExportService.generatePdf(
                      exam: exam,
                      grades: grades,
                      students: students,
                    ),
                    tooltip: "Télécharger PDF",
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_view, color: Colors.green),
                    onPressed: () => ExportService.generateExcel(
                      exam: exam,
                      grades: grades,
                      students: students,
                    ),
                    tooltip: "Télécharger Excel",
                  ),
                ],
              )
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text("Matière : ${exam.subject} | Classe : ${exam.className}"),
                  const SizedBox(height: 16),
                  const Divider(),
                  Table(
                    border: TableBorder.all(color: AppColors.border, width: 1, borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FixedColumnWidth(60),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppColors.bg),
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text("Élève", style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text("Note", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...grades.map((g) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(studentMap[g.studentId] ?? "Inconnu (${g.studentId})")),
                          Padding(padding: const EdgeInsets.all(8), child: Text(g.score.toStringAsFixed(1))),
                        ],
                      )),
                    ],
                  ),
                  if (grades.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucune note enregistrée."))),
                ],
              ),
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement des notes: $e")),
        );
      }
    }
  }
}
