import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/services/lyrics_db.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class Lyrics extends StatelessWidget {
  final int songId;

  const Lyrics({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController addLyricsController = TextEditingController();
    final lyricsDatabase = LyricsDatabase();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Lyrics', style: AppTheme.headlineMedium),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.generalDialog(
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.trash,
                                  color: Colors.red.withValues(alpha: 0.8),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete Lyrics',
                                  style: AppTheme.headlineMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Are you sure you want to delete the lyrics for this song? This action cannot be undone.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).iconTheme.color,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                FilledButton(
                                  onPressed: () {
                                    lyricsDatabase.deleteLyrics(songId);
                                    if (kDebugMode) {
                                      print("Lyrics deleted");
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Colors.red.withValues(alpha: 0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return Transform.scale(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ).value,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              );
            },
            icon: Icon(
              Iconsax.trash,
              size: 22,
              color: Colors.red.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Center(
                      child: FutureBuilder<String?>(
                        future: lyricsDatabase.getLyrics(songId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text(
                              "Error: ${snapshot.error}",
                              style: AppTheme.bodyMedium
                                  .copyWith(color: Colors.red),
                              textAlign: TextAlign.center,
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data == null) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 100),
                                Icon(
                                  Iconsax.music_square_remove,
                                  size: 64,
                                  color: Theme.of(context)
                                      .iconTheme
                                      .color
                                      ?.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No lyrics available",
                                  style: AppTheme.headlineSmall.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the + button to add lyrics",
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Text(
                              snapshot.data!,
                              style: AppTheme.headlineSmall.copyWith(
                                height: 1.8,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addLyricsController.clear(); // Clear previous text
          Get.generalDialog(
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            pageBuilder: (context, animation, secondaryAnimation) {
              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Lyrics',
                          style: AppTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: addLyricsController,
                          decoration: InputDecoration(
                            hintText: 'Paste lyrics here...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .cardColor
                                .withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 10,
                          minLines: 5,
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).iconTheme.color,
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            FilledButton(
                              onPressed: () {
                                final songLyrics = addLyricsController.text;
                                lyricsDatabase.saveLyrics(songId, songLyrics);
                                Navigator.of(context).pop();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return Transform.scale(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ).value,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
