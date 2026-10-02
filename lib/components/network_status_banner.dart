import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/localization/locale_notifier.dart';
import 'package:edugest/service/network_status_service.dart';
import 'package:flutter/material.dart';

class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        NetworkStatusService.isOnline,
        NetworkStatusService.serverUnavailable,
        appLocale,
      ]),
      builder: (context, _) {
        final isOffline = NetworkStatusService.isOnline.value == false;
        final serverUnavailable = NetworkStatusService.serverUnavailable.value;
        final message = AppLocalizations(
          appLocale.value,
        ).translate(isOffline ? 'networkError' : 'serviceUnavailable');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isOffline || serverUnavailable)
              Material(
                color: isOffline
                    ? const Color(0xFF8A3B12)
                    : const Color(0xFF9B1C1C),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
