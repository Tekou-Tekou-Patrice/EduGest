import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/pages/absences.dart';
import 'package:edugest/pages/discipline.dart';
import 'package:edugest/pages/liste_eleves.dart';
import 'package:edugest/pages/liste_enseignant.dart';
import 'package:edugest/pages/notes.dart';
import 'package:edugest/pages/paiements.dart';
import 'package:edugest/pages/parametres.dart';
import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/responsive_layout.dart';

class DashboardProviseur extends StatefulWidget {
  const DashboardProviseur({super.key});

  @override
  State<DashboardProviseur> createState() => _DashboardProviseurState();
}

class _DashboardProviseurState extends State<DashboardProviseur> {
  String _selectedTab = 'Tableau de bord';

  List<SidebarSection> get _sidebarSections => [
    SidebarSection(title: 'Direction', items: [
      SidebarItem(
        icon: Icons.dashboard, label: 'Tableau de bord', 
        active: _selectedTab == 'Tableau de bord',
        onTap: () => setState(() => _selectedTab = 'Tableau de bord'),
      ),
      SidebarItem(
        icon: Icons.people_alt, label: 'Gestion Staff',
        active: _selectedTab == 'Gestion Staff',
        onTap: () => setState(() => _selectedTab = 'Gestion Staff'),
      ),
      SidebarItem(
        icon: Icons.school, label: 'Élèves',
        active: _selectedTab == 'Élèves',
        onTap: () => setState(() => _selectedTab = 'Élèves'),
      ),
      SidebarItem(
        icon: Icons.groups, label: 'Enseignants',
        active: _selectedTab == 'Enseignants',
        onTap: () => setState(() => _selectedTab = 'Enseignants'),
      ),
      SidebarItem(
        icon: Icons.edit_note, label: 'Notes',
        active: _selectedTab == 'Notes',
        onTap: () => setState(() => _selectedTab = 'Notes'),
      ),
      SidebarItem(
        icon: Icons.payments, label: 'Finances',
        active: _selectedTab == 'Finances',
        onTap: () => setState(() => _selectedTab = 'Finances'),
      ),
      SidebarItem(
        icon: Icons.settings, label: 'Paramètres',
        active: _selectedTab == 'Paramètres',
        onTap: () => setState(() => _selectedTab = 'Paramètres'),
      ),
      SidebarItem(
        icon: Icons.logout, label: 'Déconnexion',
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
      appBar: isMobile ? AppBar(backgroundColor: AppColors.sidebarBg, title: Text(_selectedTab, style: const TextStyle(color: Colors.white))) : null,
      body: Row(
        children: [
          if (!isMobile) MySidebar(sections: _sidebarSections, userName: "Proviseur", userRole: "Direction"),
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
      case 'Élèves': return const ListeEleves();
      case 'Enseignants': return const ListeEnseignant();
      case 'Notes': return const Notes();
      case 'Finances': return const Paiements();
      case 'Paramètres': return const Parametres();
      default: return _buildOverview(isMobile);
    }
  }

  Widget _buildOverview(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilotage Établissement", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        Wrap(
          spacing: 20, runSpacing: 20,
          children: [
            _statCard("Effectif", "1,240", Icons.groups, Colors.blue),
            _statCard("Réussite", "78%", Icons.trending_up, Colors.green),
            _statCard("Recettes", "12.4M", Icons.payments, Colors.orange),
          ],
        ),
        const SizedBox(height: 35),
        const Text("Activités récentes du staff", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildStaffActivity(),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
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

  Widget _buildStaffActivity() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 3,
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
          title: Text("Le Censeur a mis à jour l'emploi du temps"),
          subtitle: const Text("Il y a 2 heures"),
        ),
      ),
    );
  }
}
