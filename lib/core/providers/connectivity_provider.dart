import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initial = await connectivity.checkConnectivity();
  yield initial.isNotEmpty && !initial.contains(ConnectivityResult.none);

  yield* connectivity.onConnectivityChanged.map(
    (results) =>
        results.isNotEmpty && !results.contains(ConnectivityResult.none),
  );
});
