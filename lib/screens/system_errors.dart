import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/session_manager.dart';
import '../widgets/button.dart';

class SystemErrorScreen extends StatelessWidget {
  final String status;
  const SystemErrorScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = _getConfig(context, status);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: cfg.iconBg, shape: BoxShape.circle), child: Icon(cfg.icon, size: 48, color: cfg.iconColor))
                    .animate().scale(begin: const Offset(0.4, 0.4), duration: 500.ms, curve: Curves.elasticOut).fadeIn(),
                const SizedBox(height: 28),
                Text(cfg.headline, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary), textAlign: TextAlign.center).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 12),
                Text(cfg.description, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.6)).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 36),
                HyperLocalButton(label: cfg.primaryBtnLabel, onPressed: cfg.primaryAction).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                if (cfg.secondaryBtnLabel != null) ...[
                  const SizedBox(height: 12),
                  TextButton(onPressed: cfg.secondaryAction, child: Text(cfg.secondaryBtnLabel!, style: TextStyle(color: theme.colorScheme.primary))).animate().fadeIn(delay: 350.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _EC _getConfig(BuildContext context, String status) {
    switch (status) {
      case 'no-internet':
        return _EC(icon: Icons.wifi_off_rounded, iconBg: const Color(0xFFFFE8D6), iconColor: const Color(0xFFFF6D00), headline: 'No Internet Connection', description: 'Please check your Wi-Fi or mobile data connection and try again.', primaryBtnLabel: 'Retry', primaryAction: () => context.go('/home'), secondaryBtnLabel: 'Go Home', secondaryAction: () => context.go('/home'));
      case 'server-error':
        return _EC(icon: Icons.dns_outlined, iconBg: const Color(0xFFFFDAD6), iconColor: const Color(0xFFBA1A1A), headline: 'Server Error', description: 'Something went wrong on our end. Our team has been notified. Please try again in a moment.', primaryBtnLabel: 'Try Again', primaryAction: () => context.go('/home'), secondaryBtnLabel: 'Contact Support', secondaryAction: () => context.go('/support'));
      case 'session-expired':
        return _EC(icon: Icons.lock_clock, iconBg: const Color(0xFFFFDBCB), iconColor: const Color(0xFFE65100), headline: 'Session Expired', description: 'For your security, your session has expired. Please log in again to continue.', primaryBtnLabel: 'Log In Again', primaryAction: () async { await SessionManager.clearSession(); if (context.mounted) context.go('/'); });
      case 'force-update':
        return _EC(icon: Icons.system_update_rounded, iconBg: const Color(0xFFB2F1E0), iconColor: const Color(0xFF006D5B), headline: 'Update Required', description: 'A new version of HyperLocal is available with important security patches and new features.', primaryBtnLabel: 'Update Now', primaryAction: () {}, secondaryBtnLabel: 'Remind Me Later', secondaryAction: () => context.go('/home'));
      case 'location-denied':
        return _EC(icon: Icons.location_off_rounded, iconBg: const Color(0xFFFFE8D6), iconColor: const Color(0xFFFF6D00), headline: 'Location Access Needed', description: 'HyperLocal needs location access to find nearby shops and estimate delivery times.', primaryBtnLabel: 'Open Settings', primaryAction: () {}, secondaryBtnLabel: 'Skip', secondaryAction: () => context.go('/home'));
      case 'branch-unavailable':
        return _EC(icon: Icons.store_mall_directory_outlined, iconBg: const Color(0xFFFFDAD6), iconColor: const Color(0xFFBA1A1A), headline: 'Service Unavailable', description: 'No active branches serve your area right now. We are expanding - check back soon!', primaryBtnLabel: 'Go Back', primaryAction: () => context.go('/home'));
      case 'maintenance':
      case 'server-maintenance':
        return _EC(icon: Icons.build_circle_outlined, iconBg: const Color(0xFFFFDBCB), iconColor: const Color(0xFFE65100), headline: 'Under Maintenance', description: 'HyperLocal is undergoing scheduled maintenance. We will be back shortly. Thank you for your patience.', primaryBtnLabel: 'Retry', primaryAction: () => context.go('/home'));
      default:
        return _EC(icon: Icons.error_outline, iconBg: const Color(0xFFFFDAD6), iconColor: const Color(0xFFBA1A1A), headline: 'Something Went Wrong', description: 'An unexpected error occurred. Please try refreshing the app.', primaryBtnLabel: 'Go Home', primaryAction: () => context.go('/home'));
    }
  }
}

class _EC {
  final IconData icon; final Color iconBg; final Color iconColor;
  final String headline; final String description;
  final String primaryBtnLabel; final VoidCallback primaryAction;
  final String? secondaryBtnLabel; final VoidCallback? secondaryAction;
  const _EC({required this.icon, required this.iconBg, required this.iconColor, required this.headline, required this.description, required this.primaryBtnLabel, required this.primaryAction, this.secondaryBtnLabel, this.secondaryAction});
}
