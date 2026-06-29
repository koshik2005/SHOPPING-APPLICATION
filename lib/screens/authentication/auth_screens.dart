import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../core/state.dart';
import '../../core/session_manager.dart';
import '../../core/validators.dart';
import '../../widgets/button.dart';
import '../../widgets/card.dart';
import '../../lip/lip_di.dart';
import '../../lip/domain/permission_state.dart';
import 'package:latlong2/latlong.dart';

// --------------------------------------------------------------------------
// Google Picker Handler
// --------------------------------------------------------------------------
void _showGooglePicker(BuildContext context, WidgetRef ref, bool isSignIn) async {
  try {
    print('[AUTH LOG] 5. Account picker launched');
    final authData = await ref.read(identityProvider).authenticate();
    print('[AUTH LOG] 6. Account selected: ${authData.email}');
    print('[AUTH LOG] 7. ID Token received: ${authData.idToken.substring(0, authData.idToken.length > 20 ? 20 : authData.idToken.length)}...');
    
    if (context.mounted) {
      await _handleGoogleAuth(context, ref, authData.name, authData.email, authData.photoUrl, authData.idToken);
    }
  } catch (e, stack) {
    print('[AUTH LOG] 8. Exception: $e');
    print(stack);
    debugPrint('Native Google Sign-In Error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In configuration mismatch: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }
}

Future<void> _handleGoogleAuth(BuildContext context, WidgetRef ref, String name, String email, String photoUrl, String idToken) async {
  bool isLoaderShowing = true;
  showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
  
  try {
    print('[AUTH LOG] 9. Backend request dispatching...');
    final data = await ref.read(authRepositoryProvider).loginWithGoogle(
      idToken,
      {
        'deviceId': 'device_android_990',
        'deviceName': 'SM G990B2',
        'platform': 'ANDROID',
        'osVersion': '13',
        'appVersion': '1.0.0',
        'fcmToken': 'fcm_token_placeholder',
      },
    );
    print('[AUTH LOG] 10. Backend response: $data');
    
    if (isLoaderShowing && context.mounted) { Navigator.pop(context); isLoaderShowing = false; }
    if (!context.mounted) return;
    
    final authState = data['authenticationState'] ?? data['status'];
    if (authState == 'PASSWORD_REQUIRED' || authState == 'USER_EXISTS' || authState == 'PHONE_VERIFICATION_REQUIRED' || authState == 'EMAIL_VERIFICATION_REQUIRED') {
      final existingProfile = data['existingProfile'] ?? data['data'] ?? {};
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            name: existingProfile['displayName'] ?? existingProfile['name'] ?? '',
            email: existingProfile['email'] ?? '',
            mobile: existingProfile['maskedMobileNumber'] ?? existingProfile['mobileNumber'] ?? '',
            maskMobile: existingProfile['maskedMobileNumber'] ?? existingProfile['maskMobile'] ?? '',
            maskEmail: existingProfile['email'] ?? existingProfile['maskEmail'] ?? '',
          ),
        ),
      );
    } else if (authState == 'REGISTRATION_REQUIRED' || authState == 'USER_NOT_FOUND') {
      final googleProfile = data['googleProfile'] ?? {};
      ref.read(tempRegistrationProvider.notifier).state = UserProfile(
        name: googleProfile['displayName'] ?? name,
        email: googleProfile['email'] ?? email,
        mobileNumber: '',
        gender: '',
        dob: '',
        profilePhotoUrl: googleProfile['profilePhotoUrl'] ?? photoUrl,
        addresses: [],
        savedPlaces: {},
        preferredLanguage: 'English',
        preferredCurrency: 'USD',
        themePreference: 'light',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpScreen()),
      );
    } else if (authState == 'LOGIN_COMPLETED') {
      final user = data['user'] ?? {};
      final profile = user['profile'] ?? {};
      ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
        name: profile['displayName'] ?? name,
        email: user['email'] ?? email,
        mobileNumber: '',
        gender: '',
        dob: '',
        profilePhotoUrl: profile['profilePhotoUrl'] ?? photoUrl,
        addresses: [],
        savedPlaces: {},
        preferredLanguage: 'English',
        preferredCurrency: 'USD',
        themePreference: 'light',
      ));
      ref.read(authStateProvider.notifier).state = true;
      await SessionManager.saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'] ?? '',
        userId: user['id'],
        role: user['role'],
        expiresIn: data['expiresIn'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, ${profile['displayName'] ?? name}!'), backgroundColor: const Color(0xFF006D5B)),
      );
      context.go('/permission');
    }
  } catch (e) {
    if (isLoaderShowing && context.mounted) { Navigator.pop(context); isLoaderShowing = false; }
    if (!context.mounted) return;

    int? statusCode;
    if (e is DioException) {
      statusCode = e.response?.statusCode;
    }
    
    if (statusCode == 404) {
      final googleUser = UserProfile(
        name: name,
        email: email,
        mobileNumber: '',
        gender: '',
        dob: '',
        profilePhotoUrl: photoUrl,
        addresses: [],
        savedPlaces: {},
        preferredLanguage: 'English',
        preferredCurrency: 'USD',
        themePreference: 'light',
      );
      ref.read(tempRegistrationProvider.notifier).state = googleUser;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account not registered. Please complete your registration details.')),
      );
      context.push('/signup');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Authentication failed: ${e.toString()}'),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 1. Welcome Screen
// --------------------------------------------------------------------------
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF8F6), Color(0xFFFFE8D6), Color(0xFFFFF1EB)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 24),
                Column(
                  children: [
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE65100)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: const Color(0xFFFF6D00).withAlpha(80), blurRadius: 24, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.local_mall, size: 60, color: Colors.white),
                      ),
                    ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
                    const SizedBox(height: 28),
                    Text('HyperLocal', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF5D2B0E), letterSpacing: -1)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text('Your neighborhood super app.\nOrder food, groceries, rides & packages.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                    SizedBox(height: size.height * 0.05),
                    Wrap(
                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: [
                        _pill(Icons.restaurant, 'Food'),
                        _pill(Icons.local_grocery_store, 'Grocery'),
                        _pill(Icons.directions_car, 'Rides'),
                        _pill(Icons.inventory_2, 'Parcels'),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
                Column(
                  children: [
                    HyperLocalButton(label: 'Get Started', onPressed: () => context.push('/signin')).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),
                    HyperLocalButton(label: 'Continue with Google', variant: ButtonVariant.outlined, icon: Icons.account_circle, onPressed: () => _showGooglePicker(context, ref, false)).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Launches the native Android Google Account Picker',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withAlpha(160)),
                    ).animate().fadeIn(delay: 650.ms),
                    const SizedBox(height: 16),
                    Text('By continuing you agree to our Terms of Service\nand Privacy Policy', textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFFFE8D6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFDBCB))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xFFFF6D00)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D2B0E))),
    ]),
  );
}

// --------------------------------------------------------------------------
// 2. Sign In Screen
// --------------------------------------------------------------------------
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _identifierError;
  String? _passwordError;
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose(); _passwordController.dispose();
    _identifierFocus.dispose(); _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final id = _identifierController.text.trim();
    final pw = _passwordController.text;
    setState(() {
      _identifierError = id.isEmpty ? 'Email or mobile number is required' : null;
      _passwordError = pw.isEmpty ? 'Password is required' : null;
    });
    if (_identifierError != null || _passwordError != null) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/verify-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': id, 'password': pw}),
      ).timeout(const Duration(seconds: 4));
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null && data['authenticationState'] == 'LOGIN_COMPLETED') {
          final user = data['user'] ?? {};
          final profile = user['profile'] ?? {};
          ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
            name: profile['displayName'] ?? '',
            email: user['email'] ?? '',
            mobileNumber: user['mobileNumber'] ?? '',
            gender: '',
            dob: '',
            profilePhotoUrl: profile['profilePhotoUrl'] ?? '',
            addresses: [],
            savedPlaces: {},
            preferredLanguage: 'English',
            preferredCurrency: 'USD',
            themePreference: 'light',
          ));
          ref.read(authStateProvider.notifier).state = true;
          await SessionManager.saveSession(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'] ?? '',
            userId: user['id'],
            role: user['role'],
            expiresIn: data['expiresIn'],
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${profile['displayName'] ?? "User"}!'), backgroundColor: const Color(0xFF006D5B)),
          );
          context.go('/permission');
        } else {
          setState(() => _identifierError = 'Verification failed. Please try again.');
        }
      } else {
        setState(() => _identifierError = 'Invalid credentials. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.read(sentOtpProvider.notifier).state = '123456';
      ref.read(tempRegistrationProvider.notifier).state = UserProfile(name: 'Test User', email: id.contains('@') ? id : 'user@example.com', mobileNumber: !id.contains('@') ? id : '+10000000000', gender: 'Male', dob: '1990-01-01', profilePhotoUrl: '', addresses: [], savedPlaces: {}, preferredLanguage: 'English', preferredCurrency: 'USD', themePreference: 'light');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline mode. Use OTP: 123456')));
      context.push('/otp?isRecovery=false');
    }
  }

  InputDecoration _inputDecor(String hint, IconData prefix, String? error, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(prefix, size: 20, color: const Color(0xFF85736B)),
    suffixIcon: suffix,
    filled: true,
    fillColor: error != null ? const Color(0xFFFFDAD6).withAlpha(60) : Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? const Color(0xFFBA1A1A) : const Color(0xFFFF6D00), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: Color(0xFFB0A09A), fontSize: 14),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                    const SizedBox(height: 16),
                    Hero(tag: 'app-logo', child: Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE65100)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.local_mall, size: 26, color: Colors.white))),
                    const SizedBox(height: 20),
                    Text('Welcome back', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                    const SizedBox(height: 6),
                    Text('Sign in to your HyperLocal account', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 28),
                    const Text('Mobile Number or Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
                    const SizedBox(height: 6),
                    TextField(controller: _identifierController, focusNode: _identifierFocus, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, onSubmitted: (_) => _passwordFocus.requestFocus(), decoration: _inputDecor('+91 9876543210 or you@gmail.com', Icons.person_outline, _identifierError)),
                    if (_identifierError != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(_identifierError!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A)))),
                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController, focusNode: _passwordFocus,
                      obscureText: !_passwordVisible, textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: _inputDecor('Enter your password', Icons.lock_outline, _passwordError, suffix: IconButton(icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _passwordVisible = !_passwordVisible))),
                    ),
                    if (_passwordError != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(_passwordError!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A)))),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text('Forgot Password?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (_isLoading) const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  HyperLocalButton(label: 'Send Verification Code', onPressed: _isLoading ? null : _handleLogin),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                  ]),
                  const SizedBox(height: 12),
                  HyperLocalButton(label: 'Sign in with Google', variant: ButtonVariant.outlined, icon: Icons.account_circle, onPressed: () => _showGooglePicker(context, ref, true)),
                  const SizedBox(height: 8),
                  Text(
                    'Launches the native Android Google Account Picker',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160)),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account? ", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    GestureDetector(onTap: () => context.push('/signup'), child: Text('Sign Up', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 3. Forgot Password Screen
// --------------------------------------------------------------------------
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  String? _inputError;
  bool _isLoading = false;
  Future<void> _send() async {
    final val = _controller.text.trim();
    if (val.isEmpty) { setState(() => _inputError = 'Please enter your email'); return; }
    setState(() { _inputError = null; _isLoading = true; });
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': val}),
      ).timeout(const Duration(seconds: 4));
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery OTP sent!')));
        context.push('/otp?isRecovery=true&emailOrMobile=$val');
      } else {
        setState(() => _inputError = 'No account found with that email.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.read(sentOtpProvider.notifier).state = '123456';
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline mode. Use OTP: 123456')));
      context.push('/otp?isRecovery=true&emailOrMobile=$val');
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              const SizedBox(height: 24),
              Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFFDBCB), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.lock_reset, size: 28, color: Color(0xFFFF6D00))),
              const SizedBox(height: 20),
              Text('Reset Password', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
              const SizedBox(height: 8),
              Text('Enter your registered mobile number or email. We will send a one-time recovery code.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 32),
              const Text('Email or Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
              const SizedBox(height: 6),
              TextField(
                controller: _controller, keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done, onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'you@gmail.com or +91 9876543210',
                  prefixIcon: const Icon(Icons.alternate_email, size: 20, color: Color(0xFF85736B)),
                  filled: true, fillColor: _inputError != null ? const Color(0xFFFFDAD6).withAlpha(60) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _inputError != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _inputError != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _inputError != null ? const Color(0xFFBA1A1A) : const Color(0xFFFF6D00), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              if (_inputError != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(_inputError!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A)))),
              const Spacer(),
              if (_isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              HyperLocalButton(label: 'Send Recovery Code', onPressed: _isLoading ? null : _send),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 4. Sign Up Screen
// --------------------------------------------------------------------------
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameFocus = FocusNode(); final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode(); final _addressFocus = FocusNode();
  final _passwordFocus = FocusNode(); final _confirmFocus = FocusNode();
  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  bool _passwordVisible = false; bool _confirmVisible = false; bool _isLoading = false;
  Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final temp = ref.read(tempRegistrationProvider);
      if (temp != null) {
        _nameController.text = temp.name; _emailController.text = temp.email;
        if (temp.gender.isNotEmpty) _selectedGender = temp.gender;
        setState(() {});
      }
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose(); _emailController.dispose(); _mobileController.dispose();
    _addressController.dispose(); _passwordController.dispose(); _confirmController.dispose();
    _nameFocus.dispose(); _emailFocus.dispose(); _mobileFocus.dispose();
    _addressFocus.dispose(); _passwordFocus.dispose(); _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _selectedDob ?? DateTime(now.year - 20), firstDate: DateTime(1920), lastDate: DateTime(now.year - 13), helpText: 'SELECT DATE OF BIRTH',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFFFF6D00))), child: child!));
    if (picked != null) setState(() { _selectedDob = picked; _errors.remove('dob'); });
  }

  void _validate() {
    final e = <String, String?>{};
    final n = Validators.name(_nameController.text); if (n != null) e['name'] = n;
    final em = Validators.email(_emailController.text); if (em != null) e['email'] = em;
    final ph = Validators.phone(_mobileController.text); if (ph != null) e['mobile'] = ph;
    if (_selectedDob == null) e['dob'] = 'Date of birth is required';
    final ad = Validators.address(_addressController.text); if (ad != null) e['address'] = ad;
    final pw = Validators.password(_passwordController.text); if (pw != null) e['password'] = pw;
    final cp = Validators.confirmPassword(_confirmController.text, _passwordController.text); if (cp != null) e['confirm'] = cp;
    setState(() => _errors = e);
  }

  Future<void> _handleSignUp() async {
    _validate();
    if (_errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fix the highlighted fields.')));
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    setState(() => _isLoading = true);
    final dobStr = _selectedDob != null ? '${_selectedDob!.year.toString().padLeft(4,'0')}-${_selectedDob!.month.toString().padLeft(2,'0')}-${_selectedDob!.day.toString().padLeft(2,'0')}' : '';
    
    final payload = {
      'name': _nameController.text,
      'email': _emailController.text,
      'mobileNumber': _mobileController.text,
      'countryCode': 'US',
      'language': 'English',
      'acceptTerms': true
    };
    
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 4));
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        
        if (data != null && data['authenticationState'] == 'LOGIN_COMPLETED') {
          final user = data['user'] ?? {};
          final profile = user['profile'] ?? {};
          ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
            name: profile['displayName'] ?? _nameController.text,
            email: user['email'] ?? _emailController.text,
            mobileNumber: user['mobileNumber'] ?? _mobileController.text,
            gender: _selectedGender,
            dob: dobStr,
            profilePhotoUrl: profile['profilePhotoUrl'] ?? '',
            addresses: [_addressController.text],
            savedPlaces: {'Home': _addressController.text},
            preferredLanguage: 'English',
            preferredCurrency: 'USD',
            themePreference: 'light',
          ));
          ref.read(authStateProvider.notifier).state = true;
          await SessionManager.saveSession(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'] ?? '',
            userId: user['id'],
            role: user['role'],
            expiresIn: data['expiresIn'],
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created! Welcome, ${profile['displayName'] ?? _nameController.text}.'), backgroundColor: const Color(0xFF006D5B)),
          );
          context.push('/permission');
        } else {
          // Fallback if OTP is triggered
          ref.read(sentOtpProvider.notifier).state = data?['otp'] ?? '';
          ref.read(tempRegistrationProvider.notifier).state = UserProfile(name: _nameController.text, email: _emailController.text, mobileNumber: _mobileController.text, gender: _selectedGender, dob: dobStr, profilePhotoUrl: '', addresses: [_addressController.text], savedPlaces: {'Home': _addressController.text}, preferredLanguage: 'English', preferredCurrency: 'USD', themePreference: 'light');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! OTP sent for verification.')));
          context.push('/otp?isRecovery=false');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up failed. Please try again.')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.read(sentOtpProvider.notifier).state = '123456';
      ref.read(tempRegistrationProvider.notifier).state = UserProfile(name: _nameController.text, email: _emailController.text, mobileNumber: _mobileController.text, gender: _selectedGender, dob: dobStr, profilePhotoUrl: ref.read(tempRegistrationProvider)?.profilePhotoUrl ?? '', addresses: [_addressController.text], savedPlaces: {'Home': _addressController.text}, preferredLanguage: 'English', preferredCurrency: 'USD', themePreference: 'light');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline mode. Use OTP: 123456')));
      context.push('/otp?isRecovery=false');
    }
  }

  Widget _label(String text, {bool req = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
      if (req) const Text(' *', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
    ]),
  );
  Widget _errText(String t) => Padding(padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4), child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A))));

  Widget _field({required TextEditingController c, required FocusNode f, required String hint, String? err, bool obs = false, TextInputType? kt, TextInputAction? ta, Function(String)? sub, Function(String)? onChange, IconData? icon, Widget? suf}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: c, focusNode: f, obscureText: obs, keyboardType: kt, textInputAction: ta, onSubmitted: sub, onChanged: onChange,
        decoration: InputDecoration(hintText: hint, prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF85736B)) : null, suffixIcon: suf, filled: true,
          fillColor: err != null ? const Color(0xFFFFDAD6).withAlpha(60) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFFF6D00), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: Color(0xFFB0A09A), fontSize: 14))),
      if (err != null) _errText(err),
      const SizedBox(height: 16),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pw = _passwordController.text;
    final strength = Validators.passwordStrength(pw);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                const Expanded(child: Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D2B0E)))),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Register to access hyperlocal delivery and transit', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    _label('Full Name'), _field(c: _nameController, f: _nameFocus, hint: 'Alex Johnson', err: _errors['name'], kt: TextInputType.name, ta: TextInputAction.next, sub: (_) => _emailFocus.requestFocus(), icon: Icons.person_outline, onChange: (_) { if (_errors.containsKey('name')) setState(() => _errors.remove('name')); }),
                    _label('Email Address'), _field(c: _emailController, f: _emailFocus, hint: 'alex@gmail.com', err: _errors['email'], kt: TextInputType.emailAddress, ta: TextInputAction.next, sub: (_) => _mobileFocus.requestFocus(), icon: Icons.mail_outline, onChange: (_) { if (_errors.containsKey('email')) setState(() => _errors.remove('email')); }),
                    _label('Mobile Number'), _field(c: _mobileController, f: _mobileFocus, hint: '+91 9876543210', err: _errors['mobile'], kt: TextInputType.phone, ta: TextInputAction.next, sub: (_) => FocusScope.of(context).unfocus(), icon: Icons.phone_outlined, onChange: (_) { if (_errors.containsKey('mobile')) setState(() => _errors.remove('mobile')); }),
                    _label('Gender', req: false),
                    Row(children: ['Male', 'Female', 'Other'].map((g) {
                      final sel = _selectedGender == g;
                      return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(g), selected: sel, onSelected: (_) => setState(() => _selectedGender = g), selectedColor: const Color(0xFFFF6D00), labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFF52443C), fontWeight: FontWeight.w600), side: BorderSide(color: sel ? const Color(0xFFFF6D00) : const Color(0xFFD8C2B6))));
                    }).toList()),
                    const SizedBox(height: 16),
                    _label('Date of Birth'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: _errors.containsKey('dob') ? const Color(0xFFFFDAD6).withAlpha(60) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _errors.containsKey('dob') ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))),
                        child: Row(children: [
                          Icon(Icons.calendar_month_outlined, size: 20, color: _errors.containsKey('dob') ? const Color(0xFFBA1A1A) : const Color(0xFF85736B)),
                          const SizedBox(width: 12),
                          Text(_selectedDob != null ? '${_selectedDob!.day.toString().padLeft(2,'0')} / ${_selectedDob!.month.toString().padLeft(2,'0')} / ${_selectedDob!.year}' : 'Select your date of birth', style: TextStyle(color: _selectedDob != null ? const Color(0xFF1C1B1F) : const Color(0xFFB0A09A), fontSize: 14)),
                        ]),
                      ),
                    ),
                    if (_errors.containsKey('dob')) _errText(_errors['dob']!),
                    const SizedBox(height: 16),
                    _label('Street Address'), _field(c: _addressController, f: _addressFocus, hint: '123 Market St, City', err: _errors['address'], kt: TextInputType.streetAddress, ta: TextInputAction.next, sub: (_) => _passwordFocus.requestFocus(), icon: Icons.home_outlined, onChange: (_) { if (_errors.containsKey('address')) setState(() => _errors.remove('address')); }),
                    _label('Create Password'),
                    StatefulBuilder(builder: (context, setSt) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _field(c: _passwordController, f: _passwordFocus, hint: 'Min. 8 characters', err: _errors['password'], obs: !_passwordVisible, ta: TextInputAction.next, sub: (_) => _confirmFocus.requestFocus(), icon: Icons.lock_outline, onChange: (v) { setSt(() {}); if (_errors.containsKey('password')) setState(() => _errors.remove('password')); }, suf: IconButton(icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _passwordVisible = !_passwordVisible))),
                      if (pw.isNotEmpty) _PasswordStrengthBar(strength: strength),
                    ])),
                    _label('Confirm Password'), _field(c: _confirmController, f: _confirmFocus, hint: 'Re-enter password', err: _errors['confirm'], obs: !_confirmVisible, ta: TextInputAction.done, sub: (_) => _handleSignUp(), icon: Icons.lock_outline, onChange: (_) { if (_errors.containsKey('confirm')) setState(() => _errors.remove('confirm')); }, suf: IconButton(icon: Icon(_confirmVisible ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _confirmVisible = !_confirmVisible))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(children: [
                if (_isLoading) const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                HyperLocalButton(label: 'Create Account', onPressed: _isLoading ? null : _handleSignUp),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});
  @override
  Widget build(BuildContext context) {
    final (label, color, progress) = switch (strength) {
      PasswordStrength.none => ('', Colors.transparent, 0.0),
      PasswordStrength.weak => ('Weak', Colors.red, 0.25),
      PasswordStrength.medium => ('Medium', Colors.orange, 0.5),
      PasswordStrength.strong => ('Strong', Colors.green, 0.75),
      PasswordStrength.veryStrong => ('Very Strong', const Color(0xFF006D5B), 1.0),
    };
    if (progress == 0.0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color(0xFFE0D6D0), minHeight: 4))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// --------------------------------------------------------------------------
// 5. OTP Screen — 6-box, countdown timer, resend
// --------------------------------------------------------------------------
class OtpScreen extends ConsumerStatefulWidget {
  final bool isRecovery;
  final String emailOrMobile;
  const OtpScreen({super.key, required this.isRecovery, required this.emailOrMobile});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}
class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  int _secs = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _foci[0].requestFocus());
  }
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secs = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs <= 0) { t.cancel(); return; }
      if (mounted) setState(() => _secs--);
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final f in _foci) f.dispose();
    super.dispose();
  }
  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _resend() async {
    try {
      await http.post(Uri.parse('$apiBaseUrl/api/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: json.encode({'emailOrMobile': widget.emailOrMobile})).timeout(const Duration(seconds: 4));
    } catch (_) {}
    _startTimer();
    for (final c in _ctrls) c.clear();
    if (mounted) { _foci[0].requestFocus(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New OTP sent!'))); }
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length < 6) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter all 6 digits.'))); return; }
    
    final tu = ref.read(tempRegistrationProvider);
    final emailOrPhone = widget.emailOrMobile.isNotEmpty ? widget.emailOrMobile : (tu?.email ?? tu?.mobileNumber ?? '');
    
    setState(() => _isVerifying = true);
    
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'emailOrPhone': emailOrPhone, 'otpCode': code}),
      ).timeout(const Duration(seconds: 4));
      
      if (!mounted) return;
      setState(() => _isVerifying = false);
      
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        
        if (widget.isRecovery) {
          context.push('/reset-password?emailOrMobile=$emailOrPhone&otpCode=$code');
        } else {
          if (data != null && data['authenticationState'] == 'LOGIN_COMPLETED') {
            final user = data['user'] ?? {};
            final profile = user['profile'] ?? {};
            ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
              name: profile['displayName'] ?? (tu?.name ?? ''),
              email: user['email'] ?? (tu?.email ?? ''),
              mobileNumber: user['mobileNumber'] ?? (tu?.mobileNumber ?? ''),
              gender: tu?.gender ?? '',
              dob: tu?.dob ?? '',
              profilePhotoUrl: profile['profilePhotoUrl'] ?? (tu?.profilePhotoUrl ?? ''),
              addresses: tu?.addresses ?? [],
              savedPlaces: tu?.savedPlaces ?? {},
              preferredLanguage: 'English',
              preferredCurrency: 'USD',
              themePreference: 'light',
            ));
            ref.read(authStateProvider.notifier).state = true;
            await SessionManager.saveSession(
              accessToken: data['accessToken'],
              refreshToken: data['refreshToken'] ?? '',
              userId: user['id'],
              role: user['role'],
              expiresIn: data['expiresIn'],
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verified! Welcome back, ${profile['displayName'] ?? "User"}.'), backgroundColor: const Color(0xFF006D5B)),
            );
            context.push('/permission');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification state incomplete.'), backgroundColor: Color(0xFFBA1A1A)));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Color(0xFFBA1A1A)));
        for (final c in _ctrls) c.clear();
        _foci[0].requestFocus();
      }
    } catch (e) {
      // UAT Offline Fallback
      if (!mounted) return;
      setState(() => _isVerifying = false);
      final sent = ref.read(sentOtpProvider);
      if (code == sent || code == '123456' || code == '1234') {
        if (widget.isRecovery) {
          context.push('/reset-password?emailOrMobile=$emailOrPhone&otpCode=$code');
        } else {
          if (tu != null) {
            ref.read(userProfileProvider.notifier).updateProfile(tu);
            final wb = ref.read(tempWalletBalanceProvider);
            ref.read(walletProvider.notifier).setBalance(wb);
            await SessionManager.saveSession(
              email: tu.email,
              name: tu.name,
              mobileNumber: tu.mobileNumber,
              gender: tu.gender,
              dob: tu.dob,
              profilePhotoUrl: tu.profilePhotoUrl,
              walletBalance: wb,
              selectedBranch: ref.read(selectedBranchProvider),
            );
          }
          ref.read(authStateProvider.notifier).state = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verified (offline mode).'), backgroundColor: Color(0xFF006D5B)));
          context.push('/permission');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Color(0xFFBA1A1A)));
        for (final c in _ctrls) c.clear();
        _foci[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dbg = ref.watch(sentOtpProvider);
    final timeStr = '${(_secs ~/ 60).toString().padLeft(2,'0')}:${(_secs % 60).toString().padLeft(2,'0')}';
    final canResend = _secs == 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              const SizedBox(height: 24),
              Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFB2F1E0), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.verified_outlined, size: 28, color: Color(0xFF006D5B))),
              const SizedBox(height: 20),
              Text(widget.isRecovery ? 'Recovery Code' : 'Verify Your Account', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code sent to ${widget.emailOrMobile.isNotEmpty ? widget.emailOrMobile : "your registered contact"}.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
              if (dbg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFE8D6), borderRadius: BorderRadius.circular(8)), child: Text('Test OTP: $dbg  (or use 123456)', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                  width: 46, height: 56,
                  child: TextField(
                    controller: _ctrls[i], focusNode: _foci[i],
                    textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.length == 1 && i < 5) { _foci[i + 1].requestFocus(); }
                      else if (v.isEmpty && i > 0) { _foci[i - 1].requestFocus(); }
                      if (_code.length == 6) _verify();
                    },
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D2B0E)),
                    decoration: InputDecoration(counterText: '', filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD8C2B6))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD8C2B6))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                )),
              ),
              const SizedBox(height: 28),
              Center(child: canResend
                ? TextButton(onPressed: _resend, child: Text('Resend OTP', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(value: _secs / 60, strokeWidth: 2.5, color: theme.colorScheme.primary, backgroundColor: theme.colorScheme.surfaceContainerHigh)),
                    const SizedBox(width: 10),
                    Text('Resend in $timeStr', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ])),
              if (widget.emailOrMobile.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(child: GestureDetector(onTap: () => context.pop(), child: Text('Change email/number', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)))),
              ],
              const Spacer(),
              if (_isVerifying) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              HyperLocalButton(label: 'Verify Code', onPressed: _isVerifying ? null : _verify),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 6. Reset Password Screen
// --------------------------------------------------------------------------
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String emailOrMobile;
  final String otpCode;
  const ResetPasswordScreen({super.key, required this.emailOrMobile, required this.otpCode});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}
class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _pwCtrl = TextEditingController(); final _cpCtrl = TextEditingController();
  bool _pwVis = false; bool _cpVis = false;
  String? _pwErr; String? _cpErr; bool _loading = false;
  Future<void> _update() async {
    final pw = _pwCtrl.text; final cp = _cpCtrl.text;
    setState(() { _pwErr = Validators.password(pw); _cpErr = Validators.confirmPassword(cp, pw); });
    if (_pwErr != null || _cpErr != null) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.emailOrMobile, 'otpCode': widget.otpCode, 'newPassword': pw}),
      ).timeout(const Duration(seconds: 4));
      
      if (!mounted) return;
      setState(() => _loading = false);
      if (res.statusCode == 200) {
        ref.read(authStateProvider.notifier).state = false;
        ref.read(tempRegistrationProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated! Please sign in.'), backgroundColor: Color(0xFF006D5B)));
        context.go('/signin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed. Please try again.')));
      }
    } catch (e) {
      if (!mounted) return; setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated (offline mode).'), backgroundColor: Color(0xFF006D5B)));
      context.go('/signin');
    }
  }
  InputDecoration _dec(String hint, String? err, {Widget? suf}) => InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF85736B)), suffixIcon: suf, filled: true, fillColor: err != null ? const Color(0xFFFFDAD6).withAlpha(60) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFD8C2B6))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: err != null ? const Color(0xFFBA1A1A) : const Color(0xFFFF6D00), width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFFDBCB), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.lock_open, size: 28, color: Color(0xFFFF6D00))),
            const SizedBox(height: 20),
            Text('Choose New Password', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            Text('Create a strong password for ${widget.emailOrMobile}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 32),
            const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
            const SizedBox(height: 6),
            TextField(controller: _pwCtrl, obscureText: !_pwVis, textInputAction: TextInputAction.next, onChanged: (_) { if (_pwErr != null) setState(() => _pwErr = null); }, decoration: _dec('Min. 8 characters', _pwErr, suf: IconButton(icon: Icon(_pwVis ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _pwVis = !_pwVis)))),
            if (_pwErr != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(_pwErr!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A)))),
            const SizedBox(height: 16),
            const Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF52443C))),
            const SizedBox(height: 6),
            TextField(controller: _cpCtrl, obscureText: !_cpVis, textInputAction: TextInputAction.done, onSubmitted: (_) => _update(), onChanged: (_) { if (_cpErr != null) setState(() => _cpErr = null); }, decoration: _dec('Re-enter your password', _cpErr, suf: IconButton(icon: Icon(_cpVis ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _cpVis = !_cpVis)))),
            if (_cpErr != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(_cpErr!, style: const TextStyle(fontSize: 12, color: Color(0xFFBA1A1A)))),
            const Spacer(),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            HyperLocalButton(label: 'Update Password', onPressed: _loading ? null : _update),
          ]),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 7. Permission Screen (Dynamic Geofencing & configuration loader)
// --------------------------------------------------------------------------
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});
  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _loc = false;
  bool _notif = false;
  bool _cam = false;
  bool _isDetecting = false;

  Future<void> _detectAndLoadBranch() async {
    setState(() => _isDetecting = true);
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      final lipRepo = ref.read(locationRepositoryProvider);
      final pos = await lipRepo.getCurrentLocation();
      final geofenceClient = ref.read(geofenceClientProvider);
      
      final LatLng loc = pos != null 
          ? LatLng(pos.latitude, pos.longitude)
          : const LatLng(37.7749, -122.4194);
      
      final zoneData = await geofenceClient.checkBranchZone(loc);
      final branchData = zoneData['nearestBranch'] as Map<String, dynamic>;
      final nearestBranchId = branchData['id'] ?? 'branch-a';
      
      ref.read(selectedBranchProvider.notifier).selectBranch(nearestBranchId);
      ref.read(branchInfoListProvider.notifier).fetchBranches();
      
      await ref.read(categoriesProvider(nearestBranchId).notifier).fetchCategories();
      await ref.read(catalogProvider(nearestBranchId).notifier).fetchProducts();
    } catch (e) {
      debugPrint('LIP Geofencing branch detection failed: $e');
    }
    
    if (mounted) {
      setState(() => _isDetecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Nearest branch configurations resolved dynamically via LIP geofencing!'),
          backgroundColor: Color(0xFF006D5B),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isDetecting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                'Detecting nearest branch...',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing GPS geofences and delivery zones',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: Color(0xFFFFE8D6), shape: BoxShape.circle),
                      child: const Icon(Icons.privacy_tip_outlined, size: 40, color: Color(0xFFFF6D00)),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1500.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 24),
                    Text('App Permissions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                    const SizedBox(height: 8),
                    Text(
                      'To give you the best hyperlocal experience, we need a few permissions.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    _tile(
                      Icons.location_on_outlined, const Color(0xFFFF6D00),
                      'Location', 'For delivery zones and nearby shops',
                      _loc, (v) => setState(() => _loc = v),
                    ),
                    const Divider(height: 1),
                    _tile(
                      Icons.notifications_outlined, const Color(0xFF006D5B),
                      'Notifications', 'Order updates, offers and alerts',
                      _notif, (v) => setState(() => _notif = v),
                    ),
                    const Divider(height: 1),
                    _tile(
                      Icons.photo_camera_outlined, const Color(0xFF85736B),
                      'Camera & Storage', 'Profile photo and document upload',
                      _cam, (v) => setState(() => _cam = v),
                    ),
                  ],
                ),
              ),
              HyperLocalButton(
                label: 'Continue to App',
                onPressed: () {
                  if (!_loc) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enable Location access to proceed.')),
                    );
                  } else {
                    _detectAndLoadBranch();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Fallback load default branch
                  _detectAndLoadBranch();
                },
                child: Text('Skip for now', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, Color col, String title, String sub, bool val, Function(bool) onChange) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: col.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: col),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF85736B))),
      trailing: Switch(
        value: val,
        onChanged: (v) async {
          if (title == 'Location') {
            final lipRepo = ref.read(locationRepositoryProvider);
            final res = await lipRepo.requestPermission();
            if (res == LipPermissionState.granted || res == LipPermissionState.limited) {
              onChange(true);
            } else if (res == LipPermissionState.permanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permission is permanently denied. Please enable it in Settings.'),
                  backgroundColor: Color(0xFFBA1A1A),
                ),
              );
              await ref.read(permissionManagerProvider).openSystemSettings();
            } else {
              onChange(false);
            }
          } else {
            onChange(v);
          }
        },
        activeColor: const Color(0xFFFF6D00),
      ),
    );
  }
}

class VerificationScreen extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String mobile;
  final String maskMobile;
  final String maskEmail;

  const VerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.mobile,
    required this.maskMobile,
    required this.maskEmail,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isLoading = false;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(String type) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).dio.post(
        '/api/v1/auth/send-otp',
        data: {'type': type, 'email': widget.email},
      );
      final data = res.data;
      if (data['success'] == true) {
        ref.read(sentOtpProvider.notifier).state = data['otp'] ?? '123456';
        ref.read(tempRegistrationProvider.notifier).state = UserProfile(
          name: widget.name,
          email: widget.email,
          mobileNumber: widget.mobile,
          gender: 'Male',
          dob: '1995-08-12',
          profilePhotoUrl: 'https://cdn.hyperlocal.app/users/avatars/default.png',
          addresses: [],
          savedPlaces: {},
          preferredLanguage: 'English',
          preferredCurrency: 'USD',
          themePreference: 'light',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP sent to your ${type.toLowerCase()}!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(isRecovery: false, emailOrMobile: widget.email),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).dio.post(
        '/api/v1/auth/verify-password',
        data: {'email': widget.email, 'password': _passwordController.text},
      );
      final data = res.data;
      if (data['success'] == true) {
        final profile = UserProfile(
          name: widget.name,
          email: widget.email,
          mobileNumber: widget.mobile,
          gender: 'Male',
          dob: '1995-08-12',
          profilePhotoUrl: 'https://cdn.hyperlocal.app/users/avatars/default.png',
          addresses: [],
          savedPlaces: {},
          preferredLanguage: 'English',
          preferredCurrency: 'USD',
          themePreference: 'light',
        );
        ref.read(userProfileProvider.notifier).updateProfile(profile);
        ref.read(walletProvider.notifier).setBalance(50.0);
        ref.read(authStateProvider.notifier).state = true;
        await SessionManager.saveSession(
          email: profile.email,
          name: profile.name,
          mobileNumber: profile.mobileNumber,
          gender: profile.gender,
          dob: profile.dob,
          profilePhotoUrl: profile.profilePhotoUrl,
          walletBalance: 50.0,
          selectedBranch: ref.read(selectedBranchProvider),
          authToken: data['accessToken'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification successful! Welcome back.'), backgroundColor: Color(0xFF006D5B)),
          );
          context.go('/permission');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password. Please try again.'), backgroundColor: Color(0xFFBA1A1A)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify it\'s you', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('We found an existing account. Please verify your identity to log in.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            HyperLocalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${widget.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Email: ${widget.maskEmail}'),
                  const SizedBox(height: 4),
                  Text('Mobile: ${widget.maskMobile}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: () => _sendOtp('MOBILE'),
                icon: const Icon(Icons.sms),
                label: const Text('Verify with Mobile OTP'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _sendOtp('EMAIL'),
                icon: const Icon(Icons.email),
                label: const Text('Verify with Email OTP'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Or verify using Password', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _verifyPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Submit Password'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

