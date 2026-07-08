import 'package:flutter/material.dart';
import 'app_colors.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final bool active;
  final bool locked;
  final VoidCallback? onTap;

  SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.locked = false,
    this.onTap,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;

  SidebarSection({
    required this.title,
    required this.items,
  });
}

class MySidebar extends StatelessWidget {
  final List<SidebarSection> sections;
  final String? userName;
  final String? userRole;
  final Widget? bottomTip;
  final VoidCallback? onLogout;

  const MySidebar({
    super.key,
    required this.sections,
    this.userName,
    this.userRole,
    this.bottomTip,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildBrand(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...sections.map((section) => _buildSection(section)),
                    if (bottomTip != null) bottomTip!,
                  ],
                ),
              ),
            ),
            _buildSidebarUser(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EduGest",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Collège de la Réussite",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(SidebarSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              section.title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 1,
              ),
            ),
          ),
          ...section.items.map((item) => _buildItem(item)),
        ],
      ),
    );
  }

  Widget _buildItem(SidebarItem item) {
    if (item.locked) {
      return Opacity(
        opacity: 0.4,
        child: ListTile(
          dense: true,
          leading: Icon(item.icon, color: Colors.white70, size: 18),
          title: Text(
            item.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.lock, color: Colors.white38, size: 13),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: item.active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: item.onTap,
        dense: true,
        leading: Icon(
          item.icon,
          color: item.active ? Colors.white : Colors.white70,
          size: 18,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: item.active ? Colors.white : Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarUser(BuildContext context) {
    final bool isConnected = userName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              isConnected ? Icons.person : Icons.person_outline,
              color: Colors.white38,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName ?? "Non connecté",
                  style: TextStyle(
                    color: isConnected ? Colors.white : Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole ?? "Veuillez vous connecter",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isConnected)
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.white38, size: 16),
              tooltip: "Déconnexion",
            ),
        ],
      ),
    );
  }
}
