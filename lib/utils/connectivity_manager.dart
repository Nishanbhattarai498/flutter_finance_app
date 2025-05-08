import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _isConnected = true;

  Stream<bool> get connectionStream => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connection
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    _controller.add(_isConnected);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      _controller.add(_isConnected);
    });
  }

  void dispose() {
    _controller.close();
  }
} 