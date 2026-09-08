import 'package:edugest/models/app_user.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/pages/inscription_staff.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';

class GestionStaff extends StatefulWidget {
  final AppUser currentUser;
  const GestionStaff({super.key, required this.currentUser});

  @override
  State<GestionStaff> createState() => _GestionStaffState();
}

class _GestionStaffState extends State<GestionStaff> {
  List<AppUser> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllStaff();
      if (mounted) {
        setState(() {
          _staffList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du chargement du personnel"),
          ),
        );
      }
    }
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width - 32,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: InscriptionStaff(
              currentUser: widget.currentUser,
              onSuccess: () {
                Navigator.pop(context);
                _fetchStaff();
              },
            ),
          ),
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
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Gestion du Personnel",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.currentUser.role == UserRole.fondateur ||
                    widget.currentUser.role == UserRole.proviseur ||
                    widget.currentUser.role == UserRole.secretaire)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _showAddStaffDialog,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      "Ajouter Staff",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _fetchStaff,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 25),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_staffList.isEmpty)
          const Center(child: Text("Aucun membre trouvé."))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _staffList.length,
            itemBuilder: (context, index) {
              final member = _staffList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${member.displayRole} • ${member.email}"
                    "${member.phone?.trim().isNotEmpty == true ? '\nTéléphone : ${member.phone}' : '\nTéléphone : Non renseigné'}",
                  ),
                  trailing:
                      (widget.currentUser.role == UserRole.fondateur &&
                          member.displayRole != 'Fondateur')
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirmer"),
                                content: Text(
                                  "Voulez-vous supprimer ${member.name} ?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Supprimer",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ApiService.deleteUser(member.id);
                              _fetchStaff();
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }
}
