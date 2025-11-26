import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/settings/privacy_policy.dart';
import 'package:kanyoni/features/settings/terms_conditions.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class PoliciesSettingsScreen extends StatelessWidget {
  const PoliciesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Policies'),
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
                  _buildPolicyCard(
                    context: context,
                    icon: Iconsax.document_text,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Get.to(() => const PrivacyPolicyView());
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyCard(
                    context: context,
                    icon: Iconsax.clipboard_text,
                    title: 'Terms & Conditions',
                    subtitle: 'Terms of service',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Get.to(() => const TermsConditionsView());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
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
}
