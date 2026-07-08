import 'package:edugest/components/responsive_layout.dart';
import 'package:edugest/pages/absences.dart';
import 'package:edugest/pages/cahier_texte.dart';
import 'package:edugest/pages/depenses.dart';
import 'package:edugest/pages/discipline.dart';
import 'package:edugest/pages/emploi_du_temps.dart';
import 'package:edugest/pages/evenement.dart';
import 'package:edugest/pages/gestion_classes.dart';
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
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/my_sidebar.dart';

class DashboardPage extends StatefulWidget {
  final String userRole;
  const DashboardPage({super.key, required this.userRole});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedTab = "Tableau de bord";

  void _handleNavigation(String tabName, BuildContext context) {
    setState(() => selectedTab = tabName);
    if (ResponsiveLayout.isMobile(context)) {
      Navigator.pop(context);
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  List<SidebarSection> get _sidebarSections {
    final List<SidebarSection> sections = [];

    // --- 1. SECTION PRINCIPALE ---
    sections.add(SidebarSection(
      title: "Principal",
      items: [
        SidebarItem(
          icon: Icons.dashboard,
          label: "Tableau de bord",
          active: selectedTab == "Tableau de bord",
          onTap: () => _handleNavigation("Tableau de bord", context),
        ),
        SidebarItem(
          icon: Icons.calendar_month,
          label: "Emploi du temps",
          active: selectedTab == "Emploi du temps",
          onTap: () => _handleNavigation("Emploi du temps", context),
        ),
      ],
    ));

    // --- 2. GESTION ACADÉMIQUE ---
    final List<SidebarItem> acadItems = [];
    
    acadItems.add(SidebarItem(
      icon: Icons.school,
      label: "Élèves",
      active: selectedTab == "Élèves",
      onTap: () => _handleNavigation("Élèves", context),
    ));

    if (['Proviseur', 'Secrétaire', 'Fondateur'].contains(widget.userRole)) {
      acadItems.add(SidebarItem(
        icon: Icons.people,
        label: "Enseignants",
        active: selectedTab == "Enseignants",
        onTap: () => _handleNavigation("Enseignants", context),
      ));
    }

    if (widget.userRole == 'Enseignant') {
      acadItems.add(SidebarItem(icon: Icons.edit_note, label: "Mes Notes", active: selectedTab == "Mes Notes", onTap: () => _handleNavigation("Mes Notes", context)));
      acadItems.add(SidebarItem(icon: Icons.menu_book, label: "Mon Cahier de Texte", active: selectedTab == "Mon Cahier de Texte", onTap: () => _handleNavigation("Mon Cahier de Texte", context)));
      acadItems.add(SidebarItem(icon: Icons.notifications_active, label: "Annonces Admin", active: selectedTab == "Annonces Admin", onTap: () => _handleNavigation("Annonces Admin", context)));
    } else if (['Proviseur', 'Fondateur', 'Censeur'].contains(widget.userRole)) {
      if (widget.userRole != 'Censeur') acadItems.add(SidebarItem(icon: Icons.assignment_turned_in, label: "Réception Notes", active: selectedTab == "Réception Notes", onTap: () => _handleNavigation("Réception Notes", context)));
      acadItems.add(SidebarItem(icon: Icons.library_books, label: "Réception Cahiers", active: selectedTab == "Réception Cahiers", onTap: () => _handleNavigation("Réception Cahiers", context)));
    }

    if (widget.userRole != 'Enseignant' && widget.userRole != 'Comptable') {
      acadItems.add(SidebarItem(icon: Icons.event, label: "Événements", active: selectedTab == "Événements", onTap: () => _handleNavigation("Événements", context)));
    }

    if (['Censeur', 'Proviseur', 'Fondateur'].contains(widget.userRole)) {
      acadItems.add(SidebarItem(icon: Icons.gavel, label: "Discipline", active: selectedTab == "Discipline", onTap: () => _handleNavigation("Discipline", context)));
    }

    sections.add(SidebarSection(title: "Vie Scolaire", items: acadItems));

    // --- 3. ADMINISTRATION ---
    final List<SidebarItem> adminItems = [];
    
    if (['Fondateur', 'Proviseur'].contains(widget.userRole)) {
      adminItems.add(SidebarItem(
        icon: Icons.admin_panel_settings,
        label: "Gestion Staff",
        active: selectedTab == "Gestion Staff",
        onTap: () => _handleNavigation("Gestion Staff", context),
      ));
    }

    if (['Proviseur', 'Comptable', 'Fondateur'].contains(widget.userRole)) {
      adminItems.add(SidebarItem(icon: Icons.payments, label: "Paiements", active: selectedTab == "Paiements", onTap: () => _handleNavigation("Paiements", context)));
      adminItems.add(SidebarItem(icon: Icons.account_balance, label: "Dépenses", active: selectedTab == "Dépenses", onTap: () => _handleNavigation("Dépenses", context)));
    }

    if (['Secrétaire', 'Proviseur', 'Fondateur'].contains(widget.userRole)) {
      adminItems.add(SidebarItem(icon: Icons.meeting_room, label: "Classes", active: selectedTab == "Classes", onTap: () => _handleNavigation("Classes", context)));
    }

    adminItems.add(SidebarItem(icon: Icons.settings, label: "Paramètres", active: selectedTab == "Paramètres", onTap: () => _handleNavigation("Paramètres", context)));

    sections.add(SidebarSection(title: "Administration", items: adminItems));

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile ? Drawer(child: MySidebar(sections: _sidebarSections, userName: "Staff", userRole: widget.userRole, onLogout: _logout)) : null,
      body: ResponsiveLayout(
        mobileBody: _buildMainArea(isMobile: true),
        desktopBody: Row(
          children: [
            MySidebar(sections: _sidebarSections, userName: "Staff EduGest", userRole: widget.userRole, onLogout: _logout),
            Expanded(child: _buildMainArea(isMobile: false)),
          ],
        ),
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
            child: _buildBodyContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile)
            Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
          Expanded(child: Text(selectedTab, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.textMuted), onPressed: () {}),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => selectedTab = "Profil"),
            child: const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryPale, child: Icon(Icons.person, size: 18, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (selectedTab) {
      case "Élèves": return const ListeEleves();
      case "Enseignants": return const ListeEnseignant();
      case "Mes Notes": return const Notes();
      case "Réception Notes": return const ReceptionNotes();
      case "Événements": return const Evenement();
      case "Annonces Admin": return const ReceptionEvenements();
      case "Emploi du temps": return const EmploiDuTemps();
      case "Paiements": return const Paiements();
      case "Discipline": return const Discipline();
      case "Mon Cahier de Texte": return const CahierTexte();
      case "Réception Cahiers": return const ReceptionCahierTexte();
      case "Dépenses": return const Depenses();
      case "Classes": return const GestionClasses();
      case "Paramètres": return const Parametres();
      case "Profil": return const Profil();
      case "Gestion Staff": return GestionStaff(currentUserRole: widget.userRole);
      default: return _buildRoleBasedOverview();
    }
  }

  Widget _buildRoleBasedOverview() {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    switch (widget.userRole) {
      case 'Proviseur':
        return _buildDashboardTemplate(isMobile, isTablet,
          stats: [
            _statCard("Élèves", "1,240", Icons.school, Colors.blue),
            _statCard("Réussite", "78%", Icons.trending_up, Colors.green),
            _statCard("Dettes", "1.5M", Icons.money_off, Colors.red),
            _statCard("Staff", "15", Icons.admin_panel_settings, Colors.orange),
          ],
          title: "Pilotage Administratif",
          activities: ["Réunion staff à 15h", "Bilan comptable T1 prêt", "5 absences profs à valider"],
        );
      case 'Fondateur':
        return _buildDashboardTemplate(isMobile, isTablet,
          stats: [
            _statCard("C.A Annuel", "42M", Icons.trending_up, Colors.green),
            _statCard("Effectif", "1240", Icons.people, Colors.blue),
            _statCard("Croissance", "+5%", Icons.insights, Colors.purple),
            _statCard("Budget Staff", "3.2M", Icons.payments, Colors.orange),
          ],
          title: "Vision Stratégique",
          activities: ["Validation budget labo info", "Rapport annuel des revenus", "Réunion investisseurs J-3"],
        );
      default:
        return const Center(child: Text("Bienvenue dans votre espace EduGest"));
    }
  }

  Widget _buildDashboardTemplate(bool isMobile, bool isTablet, {required List<Widget> stats, required String title, required List<String> activities}) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 3.0 : 1.3,
          children: stats,
        ),
        const SizedBox(height: 32),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
              title: Text(activities[index], style: const TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
