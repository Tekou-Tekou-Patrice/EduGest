import 'package:edugest/components/my_sidebar.dart';
import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/pages/help_manual_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp(Widget home, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  testWidgets('sidebar help opens the global French manual', (tester) async {
    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: Row(
            children: [
              SizedBox(width: 280, child: MySidebar(sections: const [])),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Aide — Manuel d’utilisation'));
    await tester.pumpAndSettle();

    expect(find.text('Manuel d’utilisation EduGest'), findsOneWidget);
    expect(find.text('2. Créer un établissement — Fondateur'), findsOneWidget);
  });

  testWidgets('global manual follows the English app language', (tester) async {
    await tester.pumpWidget(
      _testApp(const HelpManualPage(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('EduGest User Guide'), findsOneWidget);
    expect(find.text('2. Create a school — Founder'), findsOneWidget);
    expect(find.text('Browse the guide'), findsOneWidget);
  });
}
