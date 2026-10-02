import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final ValueNotifier<bool?> isOnline = ValueNotifier<bool?>(null);
  static final ValueNotifier<bool> serverUnavailable = ValueNotifier(false);
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static Future<void> initialize() async {
    _subscription ??= Connectivity().onConnectivityChanged.listen(
      _update,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Network status monitoring failed: $error');
      },
    );
    _update(await Connectivity().checkConnectivity());
  }

  static void _update(List<ConnectivityResult> results) {
    final connected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    isOnline.value = connected;
    if (!connected) {
      serverUnavailable.value = false;
    }
  }

  static void reportServerFailure() {
    if (isOnline.value != false) serverUnavailable.value = true;
  }

  static void reportServerAvailable() {
    serverUnavailable.value = false;
  }
}
