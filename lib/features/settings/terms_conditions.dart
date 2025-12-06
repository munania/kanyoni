import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                            Iconsax.document_text,
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
                                'Terms of Service',
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
                    title: 'Acceptance of Terms',
                    content:
                        'By downloading, installing, or using Kanyoni, you agree to be bound by these Terms and Conditions. '
                        'If you do not agree to these terms, please do not use the app.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'License',
                    content:
                        'Kanyoni grants you a limited, non-exclusive, non-transferable license to use the app for personal, '
                        'non-commercial purposes. You may not modify, distribute, or reverse engineer the app.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'User Responsibilities',
                    content:
                        'You are responsible for ensuring that you have the legal right to access and play any music files '
                        'on your device. Kanyoni does not provide or distribute music content and is not responsible for '
                        'copyright violations.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Disclaimer of Warranties',
                    content:
                        'Kanyoni is provided "as is" without warranties of any kind, either express or implied. We do not '
                        'guarantee that the app will be error-free, secure, or uninterrupted.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Limitation of Liability',
                    content:
                        'To the maximum extent permitted by law, Kanyoni and its developers shall not be liable for any '
                        'indirect, incidental, special, or consequential damages arising from your use of the app.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Updates and Modifications',
                    content:
                        'We reserve the right to modify, update, or discontinue the app at any time without notice. '
                        'We may also update these terms and conditions periodically.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Termination',
                    content:
                        'You may stop using the app at any time by uninstalling it from your device. We reserve the right '
                        'to terminate or restrict your access to the app for any reason.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Governing Law',
                    content:
                        'These terms shall be governed by and construed in accordance with applicable laws. Any disputes '
                        'shall be resolved in the appropriate courts.',
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    isDarkMode: isDarkMode,
                    title: 'Contact Information',
                    content:
                        'If you have any questions about these terms and conditions, please contact us through the feedback '
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
