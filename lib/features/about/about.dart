import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> with TickerProviderStateMixin {
  late AnimationController _blobController1;
  late AnimationController _blobController2;
  late AnimationController _blobController3;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Different speeds for each blob
    _blobController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _blobController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _blobController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _blobController1.dispose();
    _blobController2.dispose();
    _blobController3.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Blobs Background
          AnimatedBuilder(
            animation: Listenable.merge([
              _blobController1,
              _blobController2,
              _blobController3,
            ]),
            builder: (context, child) {
              return Stack(
                children: [
                  // Background color
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),

                  // Blob 1
                  _AnimatedBlob(
                    controller: _blobController1,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    size: 300,
                    offsetX: 0.2,
                    offsetY: 0.3,
                  ),

                  // Blob 2
                  _AnimatedBlob(
                    controller: _blobController2,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    size: 250,
                    offsetX: 0.7,
                    offsetY: 0.6,
                  ),

                  // Blob 3
                  _AnimatedBlob(
                    controller: _blobController3,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.25),
                    size: 200,
                    offsetX: 0.5,
                    offsetY: 0.8,
                  ),

                  // Blur effect
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ],
              );
            },
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // App Icon
                    _buildAppIcon(isDarkMode),

                    const SizedBox(height: 32),

                    // App Name
                    Text(
                      'Kanyoni',
                      style: AppTheme.headlineLarge.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Your Personal Music Player',
                      style: AppTheme.bodyLarge.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Description Card
                    _buildGlassCard(
                      isDarkMode: isDarkMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.music_circle,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'About',
                                style: AppTheme.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kanyoni is a beautiful, modern music player built with Flutter and GetX. '
                            'Experience your music library with stunning visuals, smooth animations, '
                            'and an intuitive interface designed for music lovers.',
                            style: AppTheme.bodyMedium.copyWith(
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Features Card
                    _buildGlassCard(
                      isDarkMode: isDarkMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.star,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Features',
                                style: AppTheme.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Iconsax.music_dashboard,
                            title: 'Beautiful Waveforms',
                            subtitle:
                                'Visualize your music with stunning waveform styles',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            icon: Iconsax.color_swatch,
                            title: 'Customizable Themes',
                            subtitle:
                                'Choose from multiple color themes and modes',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            icon: Iconsax.music_playlist,
                            title: 'Smart Playlists',
                            subtitle:
                                'Create and manage your music collections',
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            icon: Iconsax.folder_2,
                            title: 'Folder Management',
                            subtitle:
                                'Organize your library with folder blacklisting',
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Version Card
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
                              Iconsax.code_circle,
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
                                  'Version',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1.0.0',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Made with love
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Made with',
                          style: AppTheme.bodyMedium.copyWith(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.favorite,
                          color: Colors.red[400],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'using Flutter',
                          style: AppTheme.bodyMedium.copyWith(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.music,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGlassCard({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double size;
  final double offsetX;
  final double offsetY;

  const _AnimatedBlob({
    required this.controller,
    required this.color,
    required this.size,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;

        // Create circular motion
        final angle = controller.value * 2 * pi;
        final radius = 50.0;

        final x = screenSize.width * offsetX + cos(angle) * radius;
        final y = screenSize.height * offsetY + sin(angle) * radius;

        return Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
