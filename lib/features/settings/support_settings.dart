import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildSupportCard(
                    context: context,
                    icon: Iconsax.star,
                    title: 'Rate This App',
                    subtitle: 'Share your experience',
                    isDarkMode: isDarkMode,
                    onTap: () => _rateApp(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSupportCard(
                    context: context,
                    icon: Iconsax.message,
                    title: 'Feedback',
                    subtitle: 'Send us your thoughts',
                    isDarkMode: isDarkMode,
                    onTap: () => _sendFeedback(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    // For Android, use Play Store URL
    // For iOS, use App Store URL
    // You'll need to replace these with your actual app IDs
    const androidPackageName =
        'com.example.kanyoni'; // Replace with actual package name
    const iosAppId = 'YOUR_IOS_APP_ID'; // Replace with actual iOS app ID

    final Uri playStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$androidPackageName',
    );
    final Uri appStoreUri = Uri.parse(
      'https://apps.apple.com/app/id$iosAppId',
    );

    try {
      // Try to launch the appropriate store
      // In a real app, you'd detect the platform and use the appropriate URL
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appStoreUri)) {
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open app store'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@kanyoni.app', // Replace with your support email
      query: 'subject=Kanyoni Feedback&body=Hi Kanyoni Team,%0A%0A',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }
}
