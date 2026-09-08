import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../service/api_service.dart';
import '../service/auth_session_service.dart';
import '../service/notification_service.dart';
import '../service/school_notifier.dart';
import 'home_router.dart';
import 'login_page.dart';
import 'school_access_page.dart';

class SchoolSelectionPage extends StatefulWidget {
  final AppUser user;
  const SchoolSelectionPage({super.key, required this.user});

  @override
  State<SchoolSelectionPage> createState() => _SchoolSelectionPageState();
}

class _SchoolSelectionPageState extends State<SchoolSelectionPage> {
  late Future<List<School>> _schools;
  late AppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _schools = ApiService.getUserSchools(widget.user.id);
  }

  Future<void> _select(School school) async {
    try {
      final effectiveRole = school.role ?? _user.role;
      final selectedUser = _user.copyWith(role: effectiveRole);
      _user = selectedUser;

      // 1. Informer le serveur du choix de l'école
      await ApiService.selectSchool(userId: _user.id, schoolId: school.id);

      // 2. Activer l'ID dans le client API pour les futures requêtes
      ApiService.setActiveSchool(school.id);
      ApiService.setActiveUser(_user);

      // 3. Sauvegarder la session localement avec le rôle lié à l'école choisie
      await AuthSessionService.saveSession(_user, schoolId: school.id);

      // 4. Forcer la mise à jour globale des infos de l'école (nom, logo, etc.)
      // Cela évite l'erreur "Aucune école active" au chargement du dashboard
      await currentSchoolNotifier.fetchSchoolInfo();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeRouter(userRole: _user.displayRole, user: _user),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de sélection : ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSchoolAccess() async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SchoolAccessPage(user: _user)),
    );
    if (joined == true && mounted) {
      setState(() => _schools = ApiService.getUserSchools(_user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.translate('mySchools')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
            tooltip: loc.translate('logout'),
            onPressed: () async {
              NotificationService.instance.stop();
              ApiService.activeSchoolId = null;
              ApiService.clearActiveUser();
              await AuthSessionService.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<School>>(
        future: _schools,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(loc.translate('schoolLoadingError')),
            );
          }
          final schools = snapshot.data ?? [];
          if (schools.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        loc.translate('noSchoolMembership'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openSchoolAccess,
                        icon: const Icon(Icons.add_business),
                        label: Text(
                          loc.translate('joinOrCreateSchool'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                loc.translate('selectSchoolToManage'),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...schools.map(
                    (school) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: AppColors.primary),
                      ),
                      title: Text(
                        school.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(school.address ?? loc.translate('undefinedAddress')),
                          if (school.role != null)
                            Text(
                              'Rôle: ${school.roleLabel}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _select(school),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _openSchoolAccess,
                icon: const Icon(Icons.add),
                label: Text(loc.translate('addAnotherSchool')),
              ),
            ],
          );
        },
      ),
    );
  }
}