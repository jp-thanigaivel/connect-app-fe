import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/pages/users_landing_page.dart';
import 'package:connect/pages/recent_page.dart';
import 'package:connect/pages/profile_page.dart';
import 'package:connect/pages/settlements_landing_page.dart';
import 'package:connect/pages/expert_details_page.dart';
import 'package:connect/core/api/token_manager.dart';

@NowaGenerated()
class MainNavigationPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

@NowaGenerated()
class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  String? _userType;
  List<Widget> _pages = [
    const Center(child: CircularProgressIndicator()),
    const RecentPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  Future<void> _initializePages() async {
    final userType = await TokenManager.getUserType();
    if (mounted) {
      setState(() {
        _userType = userType;
        if (userType == 'EXPERT') {
          _pages = [
            const SettlementsLandingPage(),
            const RecentPage(),
            const ExpertDetailsPage(),
            const ProfilePage(),
          ];
        } else {
          _pages = [
            const UsersLandingPage(),
            const RecentPage(),
            const ProfilePage(),
          ];
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userType == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isExpert = _userType == 'EXPERT';

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          height: 70,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Recent',
            ),
            if (isExpert)
              const NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology),
                label: 'Expert',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
