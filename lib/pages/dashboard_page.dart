import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/absences.dart';
import 'package:edugest/pages/cahier_texte.dart';
import 'package:edugest/pages/depenses.dart';
import 'package:edugest/pages/finances_page.dart';
import 'package:edugest/pages/discipline.dart';
import 'package:edugest/pages/emploi_du_temps.dart';
import 'package:edugest/pages/evenement.dart';
import 'package:edugest/pages/gestion_classes.dart';
import 'package:edugest/pages/gestion_matieres.dart';
import 'package:edugest/pages/gestion_staff.dart';
import 'package:edugest/pages/liste_eleves.dart';
import 'package:edugest/pages/liste_enseignant.dart';
import 'package:edugest/pages/login_page.dart';
import 'package:edugest/pages/notes.dart';
import 'package:edugest/pages/paiements.dart';
import 'package:edugest/pages/parametres.dart';
import 'package:edugest/pages/profil.dart';
import 'package:edugest/pages/reception_notes.dart';
import 'package:edugest/pages/reception_cahier_texte.dart';
import 'package:edugest/pages/reception_evenements.dart';
import 'package:edugest/pages/appel_page.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/service/api_service.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:edugest/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:edugest/pages/recap_annees.dart';
import 'package:edugest/pages/bulletins_page.dart';
import 'package:edugest/pages/programme_page.dart';
import 'package:edugest/pages/teacher_room_check_page.dart';
import 'package:edugest/pages/school_selection_page.dart';
import 'package:edugest/models/school_info.dart';
import 'package:edugest/service/school_notifier.dart';
import '../components/app_colors.dart';
import '../components/my_sidebar.dart';

class DashboardPage extends StatefulWidget {
  final AppUser currentUser;
  const DashboardPage({super.key, required this.currentUser});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedTab = 'dashboard';
  int _studentCount = 0;
  int _staffCount = 0;
  num _financeReceived = 0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveStats();
    if (widget.currentUser.role == UserRole.parent) {
      selectedTab = 'receptionNotes';
    }
  }

  Future<void> _loadLiveStats() async {
    try {
      final students = await ApiService.getStudents();
      final staff = await ApiService.getAllStaff();
      final stats = await ApiService.getFinanceStats();
      if (mounted) {
        setState(() {
          _studentCount = students.length;
          _staffCount = staff.length;
          _financeReceived =
              stats['totalReceived'] ?? stats['totalIncomes'] ?? 0;
          _isStatsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  void _handleNavigation(String tabName, BuildContext context) {
    setState(() => selectedTab = tabName);
    if (ResponsiveLayout.isMobile(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    NotificationService.instance.stop();
    ApiService.activeSchoolId = null;
    ApiService.clearActiveUser();
    await AuthSessionService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  String _tabLabel(AppLocalizations loc, String tabKey) {
    switch (tabKey) {
      case 'dashboard':
        return loc.translate('dashboard');
      case 'timetable':
        return loc.translate('timetable');
      case 'appel':
        return 'Faire l\'appel';
      case 'students':
        return loc.translate('students');
      case 'teachers':
        return 'Liste Enseignants';
      case 'myNotes':
        return 'Notes & Évaluations';
      case 'myNotebook':
        return 'Cahier de Texte';
      case 'adminAnnouncements':
        return 'Notifications & Annonces';
      case 'receptionNotes':
        return 'Mes Notes / Enfants';
      case 'receptionNotebooks':
        return 'Cahier de Texte';
      case 'events':
        return 'Événements';
      case 'discipline':
        return 'Discipline & Sanctions';
      case 'absences':
        return 'Absences';
      case 'managementStaff':
        return 'Gestion du Staff';
      case 'payments':
        return 'Paiements Scolaires';
      case 'expenses':
        return 'Dépenses';
      case 'finances':
        return 'Tableau de Bord Financier';
      case 'classes':
        return 'Gestion des Classes';
      case 'subjects':
        return 'Gestion des Matières';
      case 'bulletins':
        return 'Bulletins Scolaires';
      case 'recapYears':
        return 'Récapitulatif Années';
      case 'settings':
        return 'Paramètres';
      case 'profile':
        return 'Mon Profil';
      case 'programme':
        return 'Programme et progression';
      case 'teacherRoomChecks':
        return 'Présence des enseignants';
      default:
        return loc.translate('dashboard');
    }
  }

  SidebarItem _navItem(AppLocalizations loc, IconData icon, String tabKey) {
    return SidebarItem(
      icon: icon,
      label: _tabLabel(loc, tabKey),
      active: selectedTab == tabKey,
      onTap: () => _handleNavigation(tabKey, context),
    );
  }

  List<SidebarSection> get _sidebarSections {
    final loc = AppLocalizations.of(context);
    final role = widget.currentUser.role;

    final bool isFondateur = role == UserRole.fondateur;
    final bool isProviseur = role == UserRole.proviseur;
    final bool isCenseur = role == UserRole.censeur;
    final bool isSecretaire = role == UserRole.secretaire;
    final bool isSG =
        role == UserRole.surveillantGeneral || role == UserRole.surveillant;
    final bool isComptable = role == UserRole.comptable;
    final bool isEnseignant = role == UserRole.enseignant;
    final bool isParent = role == UserRole.parent;

    final List<SidebarSection> sections = [];

    // 1. SECTION PRINCIPALE
    if (!isParent) {
      sections.add(
        SidebarSection(
          title: loc.translate('principal'),
          items: [
            _navItem(loc, Icons.dashboard, 'dashboard'),
            if (isFondateur || isCenseur || isSG || isEnseignant)
              _navItem(loc, Icons.calendar_month, 'timetable'),
            if (isEnseignant) _navItem(loc, Icons.how_to_reg, 'appel'),
          ],
        ),
      );
    }

    // 2. VIE SCOLAIRE & PEDAGOGIE
    final List<SidebarItem> acadItems = [];
    if (isFondateur || isSecretaire) {
      acadItems.add(_navItem(loc, Icons.school, 'students'));
    }
    if (isFondateur || isProviseur) {
      acadItems.add(_navItem(loc, Icons.people, 'teachers'));
    }
    if (isFondateur || isCenseur || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.edit_note, 'myNotes'));
    }
    if (isFondateur || isCenseur || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.menu_book, 'myNotebook'));
    }
    if (isFondateur || isProviseur || isCenseur || isSecretaire) {
      acadItems.add(_navItem(loc, Icons.event, 'events'));
    }
    if (isFondateur || isSG) {
      acadItems.add(_navItem(loc, Icons.event_busy, 'absences'));
    }
    if (isFondateur || isProviseur || isCenseur || isSG || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.gavel, 'discipline'));
    }
    if (isFondateur || isProviseur || isCenseur) {
      acadItems.add(_navItem(loc, Icons.assignment, 'bulletins'));
    }
    if (isFondateur || isProviseur || isSecretaire || isEnseignant || isParent) {
      acadItems.add(_navItem(loc, Icons.menu_book, 'programme'));
    }
    if (isFondateur || isProviseur || isSecretaire || isSG || isEnseignant) {
      acadItems.add(_navItem(loc, Icons.fact_check, 'teacherRoomChecks'));
    }
    if (acadItems.isNotEmpty) {
      sections.add(SidebarSection(title: 'Vie Scolaire', items: acadItems));
    }

    // 3. ADMINISTRATION & FINANCE
    final List<SidebarItem> adminItems = [];
    if (isFondateur || isProviseur) {
      adminItems.add(_navItem(loc, Icons.history_edu, 'recapYears'));
    }
    if (isFondateur || isSecretaire) {
      adminItems.add(
        _navItem(loc, Icons.admin_panel_settings, 'managementStaff'),
      );
    }
    if (isFondateur || isComptable || isParent) {
      adminItems.add(_navItem(loc, Icons.payments, 'payments'));
    }
    if (isFondateur || isComptable) {
      adminItems.add(_navItem(loc, Icons.account_balance, 'expenses'));
    }
    if (isFondateur || isComptable) {
      adminItems.add(_navItem(loc, Icons.bar_chart, 'finances'));
    }
    if (isFondateur || isProviseur || isCenseur) {
      adminItems.add(_navItem(loc, Icons.meeting_room, 'classes'));
      adminItems.add(_navItem(loc, Icons.book_outlined, 'subjects'));
    }
    if (isFondateur) {
      adminItems.add(_navItem(loc, Icons.settings, 'settings'));
    }

    if (adminItems.isNotEmpty) {
      sections.add(SidebarSection(title: 'Administration', items: adminItems));
    }

    // 4. COMMUNICATION
    final List<SidebarItem> commItems = [];
    if (isFondateur || isSecretaire || isSG || isComptable || isParent) {
      commItems.add(
        _navItem(loc, Icons.notifications_active, 'adminAnnouncements'),
      );
    }
    if (isParent) {
      commItems.add(_navItem(loc, Icons.assessment, 'receptionNotes'));
      commItems.add(_navItem(loc, Icons.library_books, 'receptionNotebooks'));
    }
    if (commItems.isNotEmpty) {
      sections.add(SidebarSection(title: "Communication", items: commItems));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile
          ? Drawer(
              child: MySidebar(
                sections: _sidebarSections,
                userName: widget.currentUser.name,
                userRole: widget.currentUser.displayRole,
                onLogout: _logout,
              ),
            )
          : null,
      body: isMobile
          ? _buildMainArea(isMobile: true)
          : Row(
              children: [
                MySidebar(
                  sections: _sidebarSections,
                  userName: widget.currentUser.name,
                  userRole: widget.currentUser.displayRole,
                  onLogout: _logout,
                ),
                Expanded(child: _buildMainArea(isMobile: false)),
              ],
            ),
    );
  }

  Widget _buildMainArea({required bool isMobile}) {
    return Column(
      children: [
        _buildHeader(isMobile),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildSchoolStatusBanner(), _buildBodyContent()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolStatusBanner() {
    return ValueListenableBuilder<SchoolInfo?>(
      valueListenable: currentSchoolNotifier,
      builder: (context, school, _) {
        if (school == null || !school.waitingForNewYear) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final button = widget.currentUser.role == UserRole.fondateur
                  ? ElevatedButton(
                      onPressed: () => _handleNavigation('settings', context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "Paramètres",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : null;
              final message = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.pause_circle_filled,
                    color: Colors.deepOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Année scolaire sauvegardée et archivée — En attente de renouvellement",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "L'exercice précédent a été clôturé. Rendez-vous dans les Paramètres pour démarrer la nouvelle année académique.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (button == null || constraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: message),
                    if (button != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: button,
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  message,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: button,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final loc = AppLocalizations.of(context);
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<SchoolInfo?>(
              valueListenable: currentSchoolNotifier,
              builder: (context, school, _) {
                final schoolText = school?.name.isNotEmpty == true
                    ? school!.name
                    : "EduGest";
                final yearText = school?.currentYearId.isNotEmpty == true
                    ? " • ${school!.currentYearId}"
                    : "";

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tabLabel(loc, selectedTab),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.currentUser.name} • ${widget.currentUser.displayRole} • $schoolText$yearText",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.swap_horiz,
              color: AppColors.textMuted,
            ),
            tooltip: 'Changer d’école',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SchoolSelectionPage(user: widget.currentUser),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textMuted,
            ),
            tooltip: 'Notifications',
            onPressed: _showNotifications,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => selectedTab = "profile"),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryPale,
              child: Text(
                widget.currentUser.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    try {
      final notifications = await ApiService.getUnreadNotifications(
        userId: widget.currentUser.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 460.0),
            child: notifications.isEmpty
                ? const Text('Aucune notification non lue.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, index) {
                      final notification = notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          notification['title']?.toString() ?? 'EduGest',
                        ),
                        subtitle: Text(
                          notification['message']?.toString() ?? '',
                        ),
                        onTap: () async {
                          final id = notification['id']?.toString();
                          if (id != null) {
                            await ApiService.markNotificationRead(
                              id,
                              userId: widget.currentUser.id,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les notifications: $error'),
          ),
        );
      }
    }
  }

  Widget _buildBodyContent() {
    switch (selectedTab) {
      case 'appel':
        return AppelPage(currentUser: widget.currentUser);
      case 'students':
        return ListeEleves(currentUser: widget.currentUser);
      case 'teachers':
        return const ListeEnseignant();
      case 'myNotes':
        return Notes(currentUser: widget.currentUser);
      case 'receptionNotes':
        return const ReceptionNotes();
      case 'events':
        return const Evenement();
      case 'adminAnnouncements':
        return const ReceptionEvenements();
      case 'timetable':
        return EmploiDuTemps(currentUser: widget.currentUser);
      case 'payments':
        return Paiements(currentUser: widget.currentUser);
      case 'finances':
        return FinancesPage(currentUser: widget.currentUser);
      case 'discipline':
        return Discipline(currentUser: widget.currentUser);
      case 'absences':
        return const Absences();
      case 'myNotebook':
        return CahierTexte(currentUser: widget.currentUser);
      case 'receptionNotebooks':
        return const ReceptionCahierTexte();
      case 'expenses':
        return Depenses(currentUser: widget.currentUser);
      case 'classes':
        return const GestionClasses();
      case 'subjects':
        return const GestionMatieres();
      case 'bulletins':
        return BulletinsPage(currentUser: widget.currentUser);
      case 'recapYears':
        return RecapAnnees(currentUser: widget.currentUser);
      case 'settings':
        return Parametres(currentUser: widget.currentUser);
      case 'programme':
        return ProgrammePage(currentUser: widget.currentUser);
      case 'teacherRoomChecks':
        return TeacherRoomCheckPage(currentUser: widget.currentUser);
      case 'profile':
        return Profil(user: widget.currentUser);
      case 'managementStaff':
        return GestionStaff(currentUser: widget.currentUser);
      default:
        return _buildRoleBasedOverview();
    }
  }

  Widget _buildRoleBasedOverview() {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final role = widget.currentUser.role;

    final elevesStr = _isStatsLoading ? "..." : "$_studentCount";
    final staffStr = _isStatsLoading ? "..." : "$_staffCount";
    final financeStr = _isStatsLoading ? "..." : "$_financeReceived FCFA";

    if (role == UserRole.fondateur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            "Recettes Globales",
            financeStr,
            Icons.trending_up,
            Colors.green,
          ),
          _statCard("Total Élèves", elevesStr, Icons.people, Colors.blue),
          _statCard("Membres du Staff", staffStr, Icons.badge, Colors.purple),
          _statCard("Taux de Réussite", "98%", Icons.insights, Colors.orange),
        ],
        title: "Vision Stratégique — Fondateur",
        activities: [
          "Consolidation des finances",
          "Rapport annuel des établissements",
          "Gestion des rôles critiques",
        ],
      );
    } else if (role == UserRole.proviseur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard("Élèves Inscrits", elevesStr, Icons.school, Colors.blue),
          _statCard(
            "Assiduité Globale",
            "95%",
            Icons.check_circle,
            Colors.green,
          ),
          _statCard(
            "Situation Financière",
            financeStr,
            Icons.payments,
            Colors.orange,
          ),
          _statCard(
            "Personnel Staff",
            staffStr,
            Icons.admin_panel_settings,
            Colors.purple,
          ),
        ],
        title: "Supervision et Pilotage — Direction",
        activities: [
          "Validation des bulletins en cours",
          "Revue du personnel enseignant",
          "Contrôle disciplinaire",
        ],
      );
    } else if (role == UserRole.censeur) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard("Total Élèves", elevesStr, Icons.school, Colors.blue),
          _statCard("Cahiers remplis", "88%", Icons.menu_book, Colors.teal),
          _statCard(
            "Moyenne Générale",
            "12.5",
            Icons.trending_up,
            Colors.indigo,
          ),
          _statCard("Classes", "18", Icons.meeting_room, Colors.green),
        ],
        title: "Suivi Pédagogique — Censeur",
        activities: [
          "Vérification des emplois du temps",
          "Clôture de la saisie des notes",
          "Contrôle des cahiers de texte",
        ],
      );
    } else if (role == UserRole.surveillantGeneral) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard("Élèves présents", "92%", Icons.how_to_reg, Colors.green),
          _statCard(
            "Absences du jour",
            "12",
            Icons.warning_amber_rounded,
            Colors.red,
          ),
          _statCard("Retards", "5", Icons.timer, Colors.orange),
          _statCard("Sanctions actives", "3", Icons.gavel, Colors.brown),
        ],
        title: "Vie Scolaire et Discipline — SG",
        activities: [
          "Appel des classes du matin",
          "Traitement des billets d'absence",
          "Rapport de conduite quotidien",
        ],
      );
    } else if (role == UserRole.comptable) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            "Recettes",
            financeStr,
            Icons.account_balance_wallet,
            Colors.green,
          ),
          _statCard("Dépenses", "...", Icons.shopping_cart, Colors.red),
          _statCard("Impayés", "15%", Icons.money_off, Colors.orange),
          _statCard(
            "Relances envoyées",
            "8",
            Icons.notification_important,
            Colors.blue,
          ),
        ],
        title: "Gestion Financière — Comptable",
        activities: [
          "Enregistrement des versements",
          "Paiement des fournisseurs",
          "Rapport de trésorerie",
        ],
      );
    } else if (role == UserRole.enseignant) {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard("Mes Classes", "4", Icons.groups, Colors.blue),
          _statCard("Mes Matières", "2", Icons.book, Colors.orange),
          _statCard("Heures de cours", "18h", Icons.schedule, Colors.purple),
          _statCard("Notes saisies", "75%", Icons.percent, Colors.green),
        ],
        title: "Espace Enseignant",
        activities: [
          "Remplir le cahier de texte",
          "Prendre les présences",
          "Saisir les notes d'interrogation",
        ],
      );
    } else {
      return _buildDashboardTemplate(
        isMobile,
        isTablet,
        stats: [
          _statCard(
            "Mon Profil",
            widget.currentUser.name,
            Icons.person,
            Colors.blue,
          ),
          _statCard(
            "Rôle",
            widget.currentUser.displayRole,
            Icons.badge,
            Colors.green,
          ),
          _statCard("École", "Active", Icons.school, Colors.orange),
        ],
        title: "Tableau de Bord - ${widget.currentUser.displayRole}",
        activities: ["Consulter vos informations", "Contacter l'établissement"],
      );
    }
  }

  Widget _buildDashboardTemplate(
    bool isMobile,
    bool isTablet, {
    required List<Widget> stats,
    required String title,
    required List<String> activities,
  }) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double aspectRatio = constraints.maxWidth < 600 ? 3.0 : 1.4;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: stats,
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(
                radius: 4,
                backgroundColor: AppColors.primary,
              ),
              title: Text(
                activities[index],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
