import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme.dart';
import 'navigation/router.dart';
import 'core/session_manager.dart';
import 'core/state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[AUTH LOG] 1. App starts');
  runApp(
    const ProviderScope(
      child: HyperLocalApp(),
    ),
  );
}

class HyperLocalApp extends ConsumerStatefulWidget {
  const HyperLocalApp({super.key});
  @override
  ConsumerState<HyperLocalApp> createState() => _HyperLocalAppState();
}

class _HyperLocalAppState extends ConsumerState<HyperLocalApp> {
  bool _sessionChecked = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await SessionManager.loadSession();
      if (session != null) {
        // Fetch user profile dynamically from backend to avoid stale cache
        final profile = await ref.read(customerRepositoryProvider).getProfileMe();
        ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
          name: profile['name'] ?? '',
          email: profile['email'] ?? '',
          mobileNumber: profile['mobileNumber'] ?? '',
          gender: profile['gender'] ?? '',
          dob: profile['dob'] ?? '',
          profilePhotoUrl: profile['profilePhotoUrl'] ?? '',
          addresses: [],
          savedPlaces: {},
          preferredLanguage: profile['preferredLanguage'] ?? 'English',
          preferredCurrency: profile['preferredCurrency'] ?? 'USD',
          themePreference: profile['themePreference'] ?? 'light',
        ));
        final walletBalance = (profile['walletBalance'] ?? 0.0).toDouble();
        ref.read(walletProvider.notifier).setBalance(walletBalance);
        ref.read(selectedBranchProvider.notifier).selectBranch(profile['selectedBranch'] ?? '');
        ref.read(authStateProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint('Session restore error or backend unreachable: $e');
    }
    if (mounted) setState(() => _sessionChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionChecked) {
      // Show brief branded splash while session is being restored
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _SplashScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HyperLocal Super App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8F6), Color(0xFFFFE8D6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_mall, size: 64, color: Color(0xFFFF6D00)),
              SizedBox(height: 16),
              Text('HyperLocal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D2B0E))),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
