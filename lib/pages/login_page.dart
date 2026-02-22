import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:connect/auth/google_auth_service.dart';
import 'package:connect/services/auth_api_service.dart';
import 'package:connect/services/user_api_service.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/services/user_heartbeat_manager.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:connect/services/zego_room_manager.dart';
import 'package:connect/services/call_limit_manager.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/components/promotion_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

@NowaGenerated()
class LoginPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthApiService _authApiService = AuthApiService();
  final UserApiService _userApiService = UserApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final token = await TokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final zegoResponse = await _authApiService.refreshZegoToken();
        final userProfile = await _userApiService.getUserProfile();

        if (userProfile != null) {
          await TokenManager.saveUserType(userProfile.userType);
          developer.log('Un-initializing Zego service to ensure clean state',
              name: 'LoginPage');
          await ZegoUIKitPrebuiltCallInvitationService().uninit();

          developer.log('Initializing Zego service...', name: 'LoginPage');
          await ZegoUIKitPrebuiltCallInvitationService().init(
            appID: int.parse(zegoResponse.data!.zegoAppId.toString().trim()),
            appSign: '',
            token: zegoResponse.data!.zegoToken.trim(),
            userID: userProfile.userId.trim(),
            userName: userProfile.displayName.trim(),
            plugins: [ZegoUIKitSignalingPlugin()],
            notificationConfig: ZegoCallInvitationNotificationConfig(
              androidNotificationConfig: ZegoCallAndroidNotificationConfig(
                showOnFullScreen: userProfile.userType == 'EXPERT',
                showOnLockedScreen: userProfile.userType == 'EXPERT',
              ),
            ),
            requireConfig: (ZegoCallInvitationData data) {
              final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
              config.topMenuBar.isVisible = true;
              config.topMenuBar.buttons
                  .insert(0, ZegoCallMenuBarButtonName.minimizingButton);

              config.duration.onDurationUpdate = (Duration duration) {
                CallLimitManager.instance
                    .checkDuration(duration, ZegoUIKitPrebuiltCallController());
              };

              return config;
            },
          );
          developer.log('Zego service initialized successfully',
              name: 'LoginPage');

          // Start user heartbeat for online status
          await UserHeartbeatManager.instance.start();

          // Initialize persistent room state monitoring
          ZegoRoomManager.instance.init();

          developer.log('Zego service initialized. Waiting for connection...',
              name: 'LoginPage');

          PromotionPopup.resetShownFlag();
          if (mounted) {
            Navigator.pushReplacementNamed(context, 'HomePage');
          }
        }
      } catch (e) {
        developer.log('Auto-login failed: $e', name: 'LoginPage');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleAuth = await _googleAuthService.signIn();
      developer.log('Google login successful', name: 'LoginPage');
      // if (kDebugMode) {
      //   debugPrint('Google login successful $googleAuth');
      // }

      if (googleAuth == null) {
        // User cancelled
        setState(() => _isLoading = false);
        return;
      }

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Failed to retrieve ID Token from Google');
      }
      // if (kDebugMode) {
      //   debugPrint("Retrived Info ${_googleAuthService.currentUser}");
      // }

      // Call mock backend
      final response = await _authApiService.loginWithGoogle(idToken);

      if (response.status.isSuccess && response.data != null) {
        developer.log('Backend login successful', name: 'LoginPage');

        // if (kDebugMode) {
        //   debugPrint('Backend login successful ${response.data}');
        // }

        // Fetch user profile to get correct ID and Name
        final userProfile = await _userApiService.getUserProfile();

        if (userProfile != null) {
          await TokenManager.saveUserType(userProfile.userType);
          final zegoToken = response.data!.zegoToken;
          final zegoAppId = response.data!.zegoAppId;

          // debugPrint('Zego Init - AppID: $zegoAppId');
          // debugPrint('Zego Init - UserID: ${userProfile.userId}');
          // debugPrint('Zego Init - UserName: ${userProfile.displayName}');

          if (zegoToken.isEmpty) {
            // debugPrint('WARNING: Zego Token is empty! Init will fail.');
            UiUtils.showErrorSnackBar(
                'Login Error: Zego Token missing from server');
          } else {
            // debugPrint('Zego Token Length: ${zegoToken.length}');
            // debugPrint('Zego Token Start: ${zegoToken.substring(0, 5)}...');
          }

          developer.log('Un-initializing Zego...', name: 'LoginPage');
          await ZegoUIKitPrebuiltCallInvitationService().uninit();

          developer.log('Initializing Zego service...', name: 'LoginPage');
          await ZegoUIKitPrebuiltCallInvitationService().init(
            appID: int.parse(zegoAppId.trim()),
            appSign: '', // Using token, so appSign is empty or ignored
            token: zegoToken.trim(),
            userID: userProfile.userId.trim(),
            userName: userProfile.displayName.trim(),
            plugins: [ZegoUIKitSignalingPlugin()],
            notificationConfig: ZegoCallInvitationNotificationConfig(
              androidNotificationConfig: ZegoCallAndroidNotificationConfig(
                showOnFullScreen: userProfile.userType == 'EXPERT',
                showOnLockedScreen: userProfile.userType == 'EXPERT',
              ),
            ),
            requireConfig: (ZegoCallInvitationData data) {
              final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
              config.topMenuBar.isVisible = true;
              config.topMenuBar.buttons
                  .insert(0, ZegoCallMenuBarButtonName.minimizingButton);

              config.duration.onDurationUpdate = (Duration duration) {
                CallLimitManager.instance
                    .checkDuration(duration, ZegoUIKitPrebuiltCallController());
              };

              return config;
            },
          );
          developer.log('Zego service initialized successfully',
              name: 'LoginPage');

          // Start user heartbeat for online status
          await UserHeartbeatManager.instance.start();

          // Initialize persistent room state monitoring
          ZegoRoomManager.instance.init();
        } else {
          developer.log('Failed to fetch user profile for Zego init',
              name: 'LoginPage');
        }

        PromotionPopup.resetShownFlag();

        if (mounted) {
          Navigator.pushReplacementNamed(context, 'HomePage');
        }
      } else {
        throw Exception(response.status.statusDesc);
      }
    } catch (error) {
      developer.log('Login failed: $error', name: 'LoginPage');
      // Global error handler in ApiClient handles SnackBars
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAdminLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authApiService.adminLogin(
          ApiConstants.adminPhone, ApiConstants.adminPassword);

      if (response.status.isSuccess && response.data != null) {
        developer.log('Admin login successful', name: 'LoginPage');

        final userProfile = await _userApiService.getUserProfile();
        if (userProfile != null) {
          await TokenManager.saveUserType(userProfile.userType);

          await ZegoUIKitPrebuiltCallInvitationService().uninit();
          await ZegoUIKitPrebuiltCallInvitationService().init(
            appID: int.parse(response.data!.zegoAppId.trim()),
            appSign: '',
            token: response.data!.zegoToken.trim(),
            userID: userProfile.userId.trim(),
            userName: userProfile.displayName.trim(),
            plugins: [ZegoUIKitSignalingPlugin()],
            notificationConfig: ZegoCallInvitationNotificationConfig(
              androidNotificationConfig: ZegoCallAndroidNotificationConfig(
                showOnFullScreen: userProfile.userType == 'EXPERT',
                showOnLockedScreen: userProfile.userType == 'EXPERT',
              ),
            ),
            requireConfig: (ZegoCallInvitationData data) {
              final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
              config.topMenuBar.isVisible = true;
              config.topMenuBar.buttons
                  .insert(0, ZegoCallMenuBarButtonName.minimizingButton);

              config.duration.onDurationUpdate = (Duration duration) {
                CallLimitManager.instance
                    .checkDuration(duration, ZegoUIKitPrebuiltCallController());
              };

              return config;
            },
          );

          await UserHeartbeatManager.instance.start();
          // Initialize persistent room state monitoring
          ZegoRoomManager.instance.init();

          PromotionPopup.resetShownFlag();
          if (mounted) {
            Navigator.pushReplacementNamed(context, 'HomePage');
          }
        }
      }
    } catch (e) {
      developer.log('Admin login failed: $e', name: 'LoginPage');
      // Global error handler in ApiClient handles SnackBars
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                    (isDark
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark
                        ? Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.3)
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.15),
                    (isDark
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.secondary)
                        .withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo with Glassmorphism
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/app_logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        'Welcome to Connect',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connect fast. Stay close.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 60),

                      _GoogleSignInButton(
                        onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 32),
                      if (ApiConstants.enableAdminLogin)
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      // Guest/Admin Option
                      if (ApiConstants.enableAdminLogin)
                        TextButton(
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Admin Login',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          text: 'By signing in, you agree to our ',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => launchUrl(
                                    Uri.parse(ApiConstants.legalPolicies)),
                                child: Text(
                                  'Terms and Conditions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.white,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                'https://developers.google.com/identity/images/g-logo.png',
                height: 20,
                width: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
