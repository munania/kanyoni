import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';
import 'genre_details.dart';

class GenreBean extends ISuspensionBean {
  final GenreModel genre;
  String tagIndex;

  GenreBean(this.genre)
      : tagIndex = genre.genre.isNotEmpty &&
                RegExp(r'[A-Z]').hasMatch(genre.genre[0].toUpperCase())
            ? genre.genre[0].toUpperCase()
            : '#';

  @override
  String getSuspensionTag() => tagIndex;
}

class GenreView extends StatelessWidget {
  const GenreView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final indexBarDecoration = BoxDecoration(
      color: isDarkMode
          ? Colors.grey[900]!.withAlpha(204)
          : Colors.grey[100]!.withAlpha(204),
      borderRadius: BorderRadius.circular(20),
    );

    final indexHintDecoration = BoxDecoration(
      color: Theme.of(context).primaryColor.withAlpha(197),
      shape: BoxShape.circle,
    );

    final indexBarTextStyle = TextStyle(
      fontSize: 16,
      color: isDarkMode ? Colors.white24 : Colors.black54,
      fontWeight: FontWeight.bold,
    );

    final indexBarSelectedTextStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).primaryColor,
    );

    return Obx(() {
      final genreBeans = controller.genres
          .map((genre) => GenreBean(genre))
          .toList()
        ..sort((a, b) =>
            a.genre.genre.toLowerCase().compareTo(b.genre.genre.toLowerCase()));

      // Get only A-Z tags
      final tags =
          List.generate(26, (index) => String.fromCharCode(index + 65));

      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: AzListView(
          padding:
              const EdgeInsets.only(right: 40, left: 16, top: 16, bottom: 16),
          data: genreBeans,
          itemCount: genreBeans.length,
          indexBarItemHeight: MediaQuery.of(context).size.height / 38,
          itemBuilder: (context, index) {
            final genreBean = genreBeans[index];
            return GenreCard(
              genre: genreBean.genre,
              isDarkMode: isDarkMode,
              onTap: () => Get.to(
                () => GenreDetailsView(genre: genreBean.genre),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 300),
              ),
            );
          },
          indexBarData: tags,
          // Use only A-Z tags
          indexBarOptions: IndexBarOptions(
            needRebuild: true,
            decoration: indexBarDecoration,
            indexHintDecoration: indexHintDecoration,
            indexHintAlignment: Alignment.centerRight,
            indexHintOffset: const Offset(-20, 0),
            indexHintTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textStyle: indexBarTextStyle,
            selectTextStyle: indexBarSelectedTextStyle,
          ),
          physics: const BouncingScrollPhysics(),
        ),
      );
    });
  }
}

// GenreCard class
class GenreCard extends StatelessWidget {
  final GenreModel genre;
  final bool isDarkMode;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.genre,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      ),
      child: InkWell(
        onTap: onTap,
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: QueryArtworkWidget(
                    id: genre.id,
                    type: ArtworkType.GENRE,
                    nullArtworkWidget: Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Iconsax.user,
                        size: 30,
                        color: isDarkMode
                            ? AppTheme.playerControlsDark
                            : AppTheme.playerControlsLight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genre.genre,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${genre.numOfSongs} songs',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode
                    ? AppTheme.playerControlsDark
                    : AppTheme.playerControlsLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
