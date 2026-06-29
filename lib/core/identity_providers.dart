import 'package:google_sign_in/google_sign_in.dart';
import 'google_sdk_adapter.dart';

class MissingGoogleIdTokenException implements Exception {
  final String message;
  MissingGoogleIdTokenException([this.message = 'Google ID Token is missing']);
  @override
  String toString() => "MissingGoogleIdTokenException: $message";
}

abstract class IdentityProvider {
  Future<GoogleAuthData> authenticate();
  Future<void> signOut();
}

class GoogleAuthData {
  final String name;
  final String email;
  final String photoUrl;
  final String idToken;

  GoogleAuthData({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.idToken,
  });
}

class GoogleIdentityProvider implements IdentityProvider {
  final String _serverClientId;
  final GoogleSdkAdapter _googleSdkAdapter;

  GoogleIdentityProvider(this._serverClientId, this._googleSdkAdapter);

  @override
  Future<GoogleAuthData> authenticate() async {
    if (_serverClientId.isEmpty || _serverClientId.contains('placeholder')) {
      throw Exception('GOOGLE_SERVER_CLIENT_ID is not configured. Authentication aborted.');
    }

    final account = await _googleSdkAdapter.authenticate(_serverClientId);

    if (account == null) {
      throw Exception('User cancelled sign-in');
    }

    final name = account.displayName ?? '';
    final email = account.email;
    final photoUrl = account.photoUrl ?? '';
    
    final GoogleSignInAuthentication auth = await account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.trim().isEmpty) {
      throw MissingGoogleIdTokenException();
    }

    return GoogleAuthData(
      name: name,
      email: email,
      photoUrl: photoUrl,
      idToken: idToken,
    );
  }

  @override
  Future<void> signOut() async {
    await _googleSdkAdapter.signOut();
  }
}
