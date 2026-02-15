import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:connect/globals/app_state.dart';
import 'package:connect/pages/login_page.dart';
import 'package:connect/pages/main_navigation_page.dart';
import 'package:connect/pages/payment_history_page.dart';
import 'package:connect/pages/preferred_language_page.dart';
import 'package:connect/pages/settings_page.dart';
import 'package:connect/pages/edit_profile_page.dart';
import 'package:connect/pages/terms_conditions_page.dart';
import 'package:connect/pages/privacy_policy_page.dart';
import 'package:connect/pages/profile_page.dart';
import 'package:connect/pages/edit_expert_profile_page.dart';
import 'package:connect/pages/support_tickets_page.dart';
import 'package:connect/pages/support_conversation_page.dart';
import 'package:connect/models/support_ticket.dart';
import 'package:connect/pages/expert_details_page.dart';
import 'package:connect/services/user_heartbeat_manager.dart';
import 'package:connect/services/call_heartbeat_manager.dart';
import 'dart:developer' as developer;

import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

@NowaGenerated()
import 'package:connect/globals/navigator_key.dart';

@NowaGenerated()
late final SharedPreferences sharedPrefs;

// Navigator Refactored to globals/navigator_key.dart

@NowaGenerated()
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();

  /// 1.1.2: set navigator key to ZegoUIKitPrebuiltCallInvitationService
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  runApp(const MyApp());
}

@NowaGenerated({'visibleInNowa': false})
class MyApp extends StatefulWidget {
  @NowaGenerated()
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('AppLifecycleState changed to: $state', name: 'MyApp');

    switch (state) {
      case AppLifecycleState.resumed:
        developer.log('App resumed - heartbeats continuing', name: 'MyApp');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        developer.log('App in background - heartbeats will continue',
            name: 'MyApp');
        break;
      case AppLifecycleState.detached:
        developer.log('App being terminated - stopping heartbeats',
            name: 'MyApp');
        UserHeartbeatManager.instance.stop();
        CallHeartbeatManager.instance.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (context) => AppState(),
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppState.of(context).theme,
        initialRoute: 'LoginPage',
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              ZegoUIKitPrebuiltCallMiniOverlayPage(
                contextQuery: () {
                  return navigatorKey.currentState!.context;
                },
              ),
            ],
          );
        },
        routes: {
          'HomePage': (context) => const MainNavigationPage(),
          'LoginPage': (context) => const LoginPage(),
          'PaymentHistoryPage': (context) => const PaymentHistoryPage(),
          'PreferredLanguagePage': (context) => const PreferredLanguagePage(),
          'SettingsPage': (context) => const SettingsPage(),
          'EditProfilePage': (context) => const EditProfilePage(),
          'TermsConditionsPage': (context) => const TermsConditionsPage(),
          'PrivacyPolicyPage': (context) => const PrivacyPolicyPage(),
          'ProfilePage': (context) => const ProfilePage(),
          'ExpertDetailsPage': (context) => const ExpertDetailsPage(),
          'EditExpertProfilePage': (context) => const EditExpertProfilePage(),
          'SupportTicketsPage': (context) => const SupportTicketsPage(),
          'SupportConversationPage': (context) {
            final ticket =
                ModalRoute.of(context)?.settings.arguments as SupportTicket?;
            return SupportConversationPage(
                ticket: ticket ??
                    SupportTicket(
                        id: '',
                        category: '',
                        description: '',
                        reference: SupportReference(type: '', id: ''),
                        status: '',
                        createdOn: '',
                        ticketId: ''));
          },
        },
      ),
    );
  }
}
