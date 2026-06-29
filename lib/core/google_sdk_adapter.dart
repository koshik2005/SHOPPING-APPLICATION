import 'package:google_sign_in/google_sign_in.dart';

class GoogleSdkAdapter {
  Future<GoogleSignInAccount?> authenticate(String serverClientId) async {
    print('[AUTH LOG] 3. serverClientId value loaded: $serverClientId');
    print('[AUTH LOG] 4. Google Play Services availability check: starting authentication request...');
    print('[AUTH LOG] 2. Google SDK initialized with serverClientId');
    
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    
    return await GoogleSignIn.instance.authenticate(
      scopeHint: ['email', 'profile'],
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }
}
