import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/pages/discipline.dart';
import 'package:edugest/pages/absences.dart';
import 'package:edugest/pages/evenement.dart';
import 'package:edugest/pages/emploi_du_temps.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/responsive_layout.dart';

class DashboardCenseur extends StatefulWidget {
  const DashboardCenseur({super.key});

  @override
  State<DashboardCenseur> createState() => _DashboardCenseurState();
}

class _DashboardCenseurState extends State<DashboardCenseur> {
  String _selectedTab = 'Tableau de bord';

  List<SidebarSection> get _sidebarSections => [
        SidebarSection(title: 'Discipline & Vie Scolaire', items: [
          SidebarItem(
            icon: Icons.dashboard,
            label: 'Tableau de bord',
            active: _selectedTab == 'Tableau de bord',
            onTap: () => setState(() => _selectedTab = 'Tableau de bord'),
          ),
          SidebarItem(
            icon: Icons.person_off,
            label: 'Absences',
            active: _selectedTab == 'Absences',
            onTap: () => setState(() => _selectedTab = 'Absences'),
          ),
          SidebarItem(
            icon: Icons.gavel,
            label: 'Discipline',
            active: _selectedTab == 'Discipline',
            onTap: () => setState(() => _selectedTab = 'Discipline'),
          ),
          SidebarItem(
            icon: Icons.calendar_month,
            label: 'Emploi du temps',
            active: _selectedTab == 'Emploi du temps',
            onTap: () => setState(() => _selectedTab = 'Emploi du temps'),
          ),
          SidebarItem(
            icon: Icons.event,
            label: 'Événements',
            active: _selectedTab == 'Événements',
            onTap: () => setState(() => _selectedTab = 'Événements'),
          ),
          SidebarItem(
            icon: Icons.logout,
            label: 'Déconnexion',
            onTap: () => Navigator.pop(context),
          ),
        ])
      ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile ? Drawer(child: MySidebar(sections: _sidebarSections)) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.sidebarBg,
              title: Text(_selectedTab, style: const TextStyle(color: Colors.white, fontSize: 18)),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            MySidebar(
                sections: _sidebarSections, userName: "M. le Censeur", userRole: "Discipline"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: _buildBodyContent(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(bool isMobile) {
    switch (_selectedTab) {
      case 'Absences':
        return const Absences();
      case 'Discipline':
        return const Discipline();
      case 'Événements':
        return const Evenement();
      case 'Emploi du temps':
        return const EmploiDuTemps();
      default:
        return _buildOverview(isMobile);
    }
  }

  Widget _buildOverview(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Discipline & Organisation",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 25),

        // Stats Censeur
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _statCard("Absences Jour", "14", Icons.person_off, Colors.red),
            _statCard("Retards", "8", Icons.access_time, Colors.orange),
            _statCard("Classes", "24", Icons.door_front_door, Colors.purple),
          ],
        ),

        const SizedBox(height: 35),
        const Text("Absences à traiter en priorité",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildAbsenceList(),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAbsenceList() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.warning, color: Colors.red, size: 16)),
          title: Text("Élève Nom $index - 3ème A",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text("Absence non justifiée depuis 08h00"),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
