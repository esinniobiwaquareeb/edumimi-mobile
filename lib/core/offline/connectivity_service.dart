import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityStatus {
  const ConnectivityStatus({required this.isOnline});

  final bool isOnline;
}

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<ConnectivityStatus> watchStatus() async* {
    yield await currentStatus();
    await for (final results in _connectivity.onConnectivityChanged) {
      yield _mapResults(results);
    }
  }

  Future<ConnectivityStatus> currentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    return ConnectivityStatus(isOnline: isOnline);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ref.watch(connectivityServiceProvider).watchStatus();
});
