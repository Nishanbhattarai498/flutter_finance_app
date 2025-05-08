import 'package:flutter/material.dart';
import 'package:flutter_finance_app/utils/connectivity_manager.dart';

class NetworkStatus extends StatefulWidget {
  const NetworkStatus({Key? key}) : super(key: key);

  @override
  State<NetworkStatus> createState() => _NetworkStatusState();
}

class _NetworkStatusState extends State<NetworkStatus> {
  final _connectivityManager = ConnectivityManager();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityManager.isConnected;
    _connectivityManager.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Theme.of(context).colorScheme.onError,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'You are offline',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 