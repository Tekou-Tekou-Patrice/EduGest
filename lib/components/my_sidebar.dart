import 'package:flutter/material.dart';
import '../models/school_info.dart';
import '../service/school_notifier.dart';
import '../localization/app_localizations.dart';
import '../pages/help_manual_page.dart';
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

  SidebarSection({required this.title, required this.items});
}

class MySidebar extends StatelessWidget {
  final List<SidebarSection> sections;
  final String? userName;
  final String? userRole;
  final Widget? bottomTip;
  final VoidCallback? onLogout;
  final VoidCallback? onSwitchSchool;

  const MySidebar({
    super.key,
    required this.sections,
    this.userName,
    this.userRole,
    this.bottomTip,
    this.onLogout,
    this.onSwitchSchool,
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
                    ?bottomTip,
                  ],
                ),
              ),
            ),
            _buildHelpButton(context),
            _buildSidebarUser(context),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Text(
                AppLocalizations.of(context).translate('developerCredit'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          leading: const Icon(
            Icons.help_outline,
            color: Colors.white70,
            size: 19,
          ),
          title: Text(
            AppLocalizations.of(context).translate('helpManual'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HelpManualPage()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrand() {
    // Déclenche le chargement si non initialisé
    if (currentSchoolNotifier.value == null) {
      currentSchoolNotifier.fetchSchoolInfo();
    }

    return ValueListenableBuilder<SchoolInfo?>(
      valueListenable: currentSchoolNotifier,
      builder: (context, school, _) {
        final schoolName = (school?.name.isNotEmpty == true)
            ? school!.name
            : AppLocalizations.of(context).translate('appTitle');
        final yearLabel = (school?.currentYearId.isNotEmpty == true)
            ? "${AppLocalizations.of(context).translate('academicYear')} ${school!.currentYearId}"
            : AppLocalizations.of(context).translate('managementSystem');
        final isWaiting = school?.waitingForNewYear == true;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isWaiting ? Colors.orange : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWaiting ? Icons.hourglass_empty : Icons.school,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      yearLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isWaiting ? Colors.orangeAccent : Colors.white54,
                        fontSize: 11,
                        fontWeight: isWaiting
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSwitchSchool != null)
                IconButton(
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white60,
                    size: 18,
                  ),
                  tooltip: AppLocalizations.of(
                    context,
                  ).translate('changeSchool'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onSwitchSchool,
                ),
            ],
          ),
        );
      },
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
                color: Colors.white.withValues(alpha: 0.35),
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
        child: Material(
          color: Colors.transparent,
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
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: item.active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }

  Widget _buildSidebarUser(BuildContext context) {
    final bool isConnected = userName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                  userName ??
                      AppLocalizations.of(context).translate('notConnected'),
                  style: TextStyle(
                    color: isConnected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: isConnected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole ??
                      AppLocalizations.of(context).translate('pleaseLogin'),
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
              tooltip: AppLocalizations.of(context).translate('logout'),
            ),
        ],
      ),
    );
  }
}
