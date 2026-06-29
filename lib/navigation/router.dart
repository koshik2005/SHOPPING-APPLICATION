import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state.dart';

// Screens import declarations
import '../screens/authentication/auth_screens.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/home/shop_menu.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/mobility/mobility_screens.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/profile_screens.dart';
import '../screens/system_errors.dart';

// Navigation app shell mounter
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: isLoggedIn ? '/home' : '/',
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/' ||
          loc == '/signin' ||
          loc == '/signup' ||
          loc == '/otp' ||
          loc == '/forgot-password' ||
          loc == '/reset-password';

      if (!loggedIn && !isAuthRoute) {
        // If not logged in and not trying to access an auth page, send to welcome screen
        return '/';
      }
      if (loggedIn && isAuthRoute) {
        // If logged in and attempting to go to an auth screen, send to home
        return '/home';
      }
      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final isRecovery = state.uri.queryParameters['isRecovery'] == 'true';
          final emailOrMobile = state.uri.queryParameters['emailOrMobile'] ?? '';
          return OtpScreen(isRecovery: isRecovery, emailOrMobile: emailOrMobile);
        },
      ),
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final emailOrMobile = state.uri.queryParameters['emailOrMobile'] ?? '';
          final otpCode = state.uri.queryParameters['otpCode'] ?? '';
          return ResetPasswordScreen(emailOrMobile: emailOrMobile, otpCode: otpCode);
        },
      ),

      // Main Navigation Shell wrapping (Home, Search, Orders, Wallet, Profile tabs)
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Commerce / Flow child screens
      GoRoute(
        path: '/shop/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? 'food';
          return ShopScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      
      // Mobility & logistics
      GoRoute(
        path: '/rides',
        builder: (context, state) => const RidesScreen(),
      ),
      GoRoute(
        path: '/parcel',
        builder: (context, state) => const ParcelScreen(),
      ),

      // Profile settings / support
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/address',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/maps',
        builder: (context, state) => const MapsScreen(),
      ),

      // System Fallbacks Overlay
      GoRoute(
        path: '/system-state',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final status = extra?['status'] as String? ?? 'no-internet';
          return SystemErrorScreen(status: status);
        },
      ),
    ],
  );
});
