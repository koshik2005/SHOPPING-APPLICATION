import 'package:flutter/material';
import '../../core/auth/auth_repository.dart';
import '../../location/location_service.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();
  final _locationService = LocationService();
  bool _isTracking = false;
  String _status = 'Standby';

  void _toggleTracking() {
    setState(() {
      if (_isTracking) {
        _locationService.stopTracking();
        _isTracking = false;
        _status = 'Standby';
      } else {
        // Start background GPS coordinate simulation for order ID
        _locationService.startTracking('mock_delivery_id');
        _isTracking = true;
        _status = 'Tracking (Live GPS)';
      }
    });
  }

  void _handleLogout() async {
    _locationService.stopTracking();
    await _authRepository.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  xs: 12,
                  child: Column(
                    children: [
                      const Text('Earning Status Today', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        '\$24.50',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: Icon(_isTracking ? Icons.gps_off : Icons.gps_fixed),
                label: Text(
                  _isTracking ? 'Go Offline' : 'Go Online (Publish GPS)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
