import 'package:edugest/components/my_button.dart';
import 'package:edugest/components/app_colors.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/service/auth_session_service.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class Welcomepage extends StatelessWidget {
  const Welcomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo EduGest
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.28),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Titre de bienvenue
                        Text(
                          AppLocalizations.of(context).translate('welcomeTitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            AppLocalizations.of(context).translate('welcomeDescription'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Bouton Get Started
                        SizedBox(
                          width: double.infinity,
                          child: MyButton(
                            icon: Icons.arrow_right_alt,
                            text: AppLocalizations.of(context).translate('getStarted'),
                            onTap: () async {
                              await AuthSessionService.markWelcomeSeen();
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context).translate('developerCredit'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
