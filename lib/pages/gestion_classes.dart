import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/models/school_class.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class GestionClasses extends StatefulWidget {
  const GestionClasses({super.key});

  @override
  State<GestionClasses> createState() => _GestionClassesState();
}

class _GestionClassesState extends State<GestionClasses> {
  List<SchoolClass> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getClassrooms();
      if (!mounted) return;
      setState(() {
        _classes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de chargement des classes")),
      );
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    final tuitionCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Créer une classe"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextfield(controller: nameCtrl, hintText: "Nom (ex: 6ème A)", icon: Icons.class_),
              const SizedBox(height: 12),
              MyTextfield(controller: levelCtrl, hintText: "Niveau (ex: 6ème)", icon: Icons.layers),
              const SizedBox(height: 12),
              MyTextfield(controller: capacityCtrl, hintText: "Capacité", icon: Icons.people),
              const SizedBox(height: 12),
              MyTextfield(
                controller: tuitionCtrl,
                hintText: "Pension / frais de scolarité (FCFA)",
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              MyTextfield(controller: descCtrl, hintText: "Description", icon: Icons.notes),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                await ApiService.saveClassroom(SchoolClass(
                  id: '',
                  name: nameCtrl.text.trim(),
                  level: levelCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : levelCtrl.text.trim(),
                  capacity: int.tryParse(capacityCtrl.text) ?? 40,
                  tuitionFee: double.tryParse(tuitionCtrl.text.replaceAll(',', '.')) ?? 0,
                  description: descCtrl.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context);
                await _fetchClasses();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erreur lors de la création")),
                  );
                }
              }
            },
            child: const Text("Créer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text(
              "Gestion des Classes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            MyButton(icon: Icons.add_home_work, text: "Créer une classe", onTap: _showCreateDialog),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_classes.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucune classe. Créez-en une.")))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double aspectRatio = isMobile
                  ? (constraints.maxWidth < 360 ? 1.45 : 1.65)
                  : 1.8;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _classes.length,
                itemBuilder: (context, index) {
                  final c = _classes[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${c.studentCount} Élèves • Capacité ${c.capacity}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pension : ${c.tuitionFee.toInt()} FCFA",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.teacherName != null && c.teacherName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Prof: ${c.teacherName}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () async {
                            try {
                              await ApiService.deleteClassroom(c.id);
                              await _fetchClasses();
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
