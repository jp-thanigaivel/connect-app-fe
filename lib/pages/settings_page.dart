import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/components/menu_item.dart';
import 'package:connect/globals/app_state.dart';
import 'package:connect/globals/themes.dart';
import 'package:connect/core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

@NowaGenerated()
class SettingsPage extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final isDarkMode = appState.theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Theme Toggle Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDarkMode ? 'Dark Mode' : 'Light Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    appState.changeTheme(value ? darkTheme : lightTheme);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Legal & Support',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          MenuItem(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () {
              launchUrl(Uri.parse(ApiConstants.legalPolicies));
            },
          ),
          const SizedBox(height: 12),
          MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {
              launchUrl(Uri.parse(ApiConstants.legalPolicies));
            },
          ),
          const SizedBox(height: 12),
          MenuItem(
            icon: Icons.help_outline,
            label: 'FAQs',
            onTap: () {
              launchUrl(Uri.parse(ApiConstants.legalPolicies));
            },
          ),
        ],
      ),
    );
  }
}
