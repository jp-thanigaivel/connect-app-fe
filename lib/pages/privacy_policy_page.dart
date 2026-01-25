import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class PrivacyPolicyPage extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 13, 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly to us, including your name, email address, phone number, and any other information you choose to provide.',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to monitor and analyze trends and usage.',
            ),
            _buildSection(
              context,
              '3. Information Sharing',
              'We do not share your personal information with third parties except as described in this privacy policy or with your consent.',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
            ),
            _buildSection(
              context,
              '5. Your Rights',
              'You have the right to access, update, or delete your personal information at any time. You may also opt out of receiving promotional communications from us.',
            ),
            _buildSection(
              context,
              '6. Cookies and Tracking',
              'We use cookies and similar tracking technologies to track activity on our service and hold certain information to improve and analyze our service.',
            ),
            _buildSection(
              context,
              '7. Children\'s Privacy',
              'Our service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.',
            ),
            _buildSection(
              context,
              '8. Changes to This Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            ),
            _buildSection(
              context,
              '9. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at privacy@connectapp.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
