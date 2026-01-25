import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // idToken is required for backend verification to ensure the login is authentic.
    // backend will use this token to verify the user identity against Google's servers.
    serverClientId:
        '682993784674-brrijp4udqc9ene4osi1ci4c1030dtfb.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  /// Performs Google Sign-In and returns the response containing tokens.
  Future<GoogleSignInAuthentication?> signIn() async {
    try {
      developer.log('Starting Google Sign-In flow...',
          name: 'GoogleAuthService');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('User cancelled the Google Sign-In flow.',
            name: 'GoogleAuthService');
        return null;
      }

      developer.log(
          'User signed in: ${googleUser.displayName} (${googleUser.email})',
          name: 'GoogleAuthService');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      developer.log('Tokens retrieved successfully.',
          name: 'GoogleAuthService');
      developer.log('idToken: ${googleAuth.idToken}',
          name: 'GoogleAuthService');
      developer.log('accessToken: ${googleAuth.accessToken}',
          name: 'GoogleAuthService');

      return googleAuth;
    } catch (error) {
      developer.log('Error during Google Sign-In: $error',
          name: 'GoogleAuthService');
      rethrow;
    }
  }

  /// Signs out the user.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      developer.log('User signed out.', name: 'GoogleAuthService');
    } catch (error) {
      developer.log('Error during Google Sign-Out: $error',
          name: 'GoogleAuthService');
    }
  }

  /// Returns the current signed-in user if any.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
