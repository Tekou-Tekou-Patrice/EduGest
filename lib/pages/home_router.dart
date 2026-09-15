import 'package:flutter/material.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/dashboard_page.dart';
import 'package:edugest/pages/parent_portal.dart';
import 'package:edugest/service/notification_service.dart';
import 'package:edugest/service/push_notification_service.dart';

class HomeRouter extends StatelessWidget {
  final String userRole;
  final AppUser? user;

  const HomeRouter({super.key, required this.userRole, this.user});

  @override
  Widget build(BuildContext context) {
    final effectiveUser =
        user ??
        AppUser(
          id: 'user-001',
          name: 'Utilisateur EduGest',
          email: 'user@edugest.com',
          role: AppUser.roleFromLabel(userRole),
        );
    NotificationService.instance.start(userId: effectiveUser.id);
    PushNotificationService.instance.start();

    // Redirection selon le rôle
    if (effectiveUser.role == UserRole.parent) {
      return ParentPortal(parent: effectiveUser);
    }

    // Tous les autres rôles (Proviseur, Fondateur, Censeur, Comptable, etc.)
    // utilisent le DashboardPage qui gère les permissions via la sidebar
    return DashboardPage(currentUser: effectiveUser);
  }
}
