import 'package:edugest/models/absence.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_textfield.dart';

class Absences extends StatefulWidget {
  const Absences({super.key});

  @override
  State<Absences> createState() => _AbsencesState();
}

class _AbsencesState extends State<Absences> {
  String selectedFilter = 'Toutes';
  List<Absence> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAbsences();
  }

  Future<void> _fetchAbsences() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAbsences();
      if (!mounted) return;
      setState(() {
        _absences = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des absences")),
      );
    }
  }

  void _showReportDialog() {
    final nameCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String period = 'Journée';
    bool justified = false;
    final periods = ['Matin', 'Après-midi', 'Journée'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Signaler une absence"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextfield(controller: nameCtrl, hintText: "Nom de l'élève", icon: Icons.person),
                const SizedBox(height: 12),
                MyTextfield(controller: classCtrl, hintText: "Classe", icon: Icons.class_),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: period,
                  decoration: InputDecoration(
                    labelText: "Période",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => period = v!),
                ),
                const SizedBox(height: 12),
                MyTextfield(controller: reasonCtrl, hintText: "Motif", icon: Icons.notes),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Justifiée"),
                  value: justified,
                  onChanged: (v) => setDialogState(() => justified = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await ApiService.saveAbsence(Absence(
                    id: '',
                    studentId: 'AUTO',
                    studentName: nameCtrl.text.trim(),
                    className: classCtrl.text.trim().isEmpty ? 'N/A' : classCtrl.text.trim(),
                    date: DateTime.now(),
                    period: period,
                    reason: reasonCtrl.text.trim(),
                    isJustified: justified,
                  ));
                  if (context.mounted) Navigator.pop(context);
                  await _fetchAbsences();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erreur d'enregistrement")),
                    );
                  }
                }
              },
              child: const Text("Signaler", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList =
        _absences.where((a) => selectedFilter == 'Toutes' || a.className == selectedFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            const Text(
              "Suivi des Absences",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            ElevatedButton.icon(
              onPressed: _showReportDialog,
              icon: const Icon(Icons.add_alert, color: Colors.white, size: 18),
              label: const Text("Signaler", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_absences.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucune absence signalée.")))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final a = filteredList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: a.isJustified
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      child: Icon(
                        a.isJustified ? Icons.check : Icons.close,
                        color: a.isJustified ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${a.className} • ${a.period} • ${DateFormat('dd/MM/yyyy').format(a.date)}",
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          if (a.reason.isNotEmpty)
                            Text(a.reason, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      a.isJustified ? "Justifiée" : "Non justifiée",
                      style: TextStyle(
                        color: a.isJustified ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
