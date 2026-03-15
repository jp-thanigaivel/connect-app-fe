import 'package:google_sign_in/google_sign_in.dart';
import 'package:connect/core/utils/app_logger.dart';

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
      AppLogger.info('Starting Google Sign-In flow...', name: 'GoogleAuthService');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.info('User cancelled the Google Sign-In flow.', name: 'GoogleAuthService');
        return null;
      }

      AppLogger.info('User signed in: ${googleUser.displayName} (${googleUser.email})', name: 'GoogleAuthService');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      AppLogger.info('Tokens retrieved successfully.', name: 'GoogleAuthService');
      AppLogger.info('idToken: ${googleAuth.idToken}', name: 'GoogleAuthService');
      AppLogger.info('accessToken: ${googleAuth.accessToken}', name: 'GoogleAuthService');

      return googleAuth;
    } catch (error) {
      AppLogger.error('Error during Google Sign-In: $error', name: 'GoogleAuthService');
      rethrow;
    }
  }

  /// Signs out the user.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      AppLogger.info('User signed out.', name: 'GoogleAuthService');
    } catch (error) {
      AppLogger.error('Error during Google Sign-Out: $error', name: 'GoogleAuthService');
    }
  }

  /// Returns the current signed-in user if any.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
