//import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkService {
  // final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  // continuously listen to internet status
  Stream<bool> get isOnline async* {
    while (true) {
      final hasInternet = await _internetChecker.hasInternetAccess;
      yield hasInternet;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  // One-time check
  Future<bool> checkNow() async {
    return await _internetChecker.hasInternetAccess;
  }
}

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

final networkStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(networkServiceProvider);
  return service.isOnline;
});

/*
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  final StreamController<bool> _controller = StreamController.broadcast();

  Stream<bool> get status async* {
    // emit initial state
    yield await _internetChecker.hasInternetAccess;

    // listen to connectivity changes
    await for (final _ in _connectivity.onConnectivityChanged) {
      final hasInternet = await _internetChecker.hasInternetAccess;
      _controller.add(hasInternet);
    }
  }

  // expose stream
  Stream<bool> get isOnline => _controller.stream;

  Future<bool> checkNow() async {
    return await _internetChecker.hasInternetAccess;
  }

  void dispose() {
    _controller.close();
  }
}
 */
