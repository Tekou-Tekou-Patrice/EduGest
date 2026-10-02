import 'package:edugest/components/network_status_banner.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/service/network_status_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('server unavailable banner disappears after five seconds', (
    tester,
  ) async {
    appLocale.setLocale(const Locale('fr'));
    NetworkStatusService.isOnline.value = true;
    NetworkStatusService.reportServerFailure();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NetworkStatusBanner(child: SizedBox.expand())),
      ),
    );

    expect(
      find.text(
        'Le service est temporairement indisponible. Réessayez plus tard.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(
      find.text(
        'Le service est temporairement indisponible. Réessayez plus tard.',
      ),
      findsNothing,
    );

    NetworkStatusService.reportServerAvailable();
    NetworkStatusService.isOnline.value = null;
  });
}
