import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildGlassCard(
                    isDarkMode: isDarkMode,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.shield_tick,
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
                                'Your Privacy Matters',
                                style: AppTheme.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: November 2025',
                                style: AppTheme.bodySmall.copyWith(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content sections
                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Information We Collect',
                    content:
                        'Kanyoni is a local music player that operates entirely on your device. '
                        'We do not collect, store, or transmit any personal information to external servers. '
                        'All your music files, playlists, and preferences remain on your device.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Local Storage',
                    content:
                        'The app stores your preferences, playlists, and playback history locally on your device '
                        'using secure storage mechanisms. This data is never shared with third parties and remains '
                        'under your control.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Permissions',
                    content:
                        'Kanyoni requires storage permissions to access your music files. These permissions are used '
                        'solely to scan and play your local music library. We do not access any other files or data '
                        'on your device.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Third-Party Services',
                    content:
                        'This app does not integrate with any third-party analytics, advertising, or tracking services. '
                        'Your music listening habits and preferences are completely private.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Data Security',
                    content:
                        'Since all data is stored locally on your device, the security of your information depends on '
                        'your device\'s security measures. We recommend keeping your device protected with a password '
                        'or biometric authentication.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Changes to This Policy',
                    content:
                        'We may update this privacy policy from time to time. Any changes will be reflected in the app '
                        'and the "Last updated" date will be revised accordingly.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Contact Us',
                    content:
                        'If you have any questions about this privacy policy, please contact us through the feedback '
                        'option in the app.',
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection({
    required bool isDarkMode,
    required String title,
    required String content,
  }) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTheme.bodyMedium.copyWith(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
