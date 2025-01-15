import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';
import 'artists_details.dart';

class ArtistBean extends ISuspensionBean {
  final ArtistModel artist;
  String tagIndex = "";

  ArtistBean(this.artist) {
    final firstChar = artist.artist[0].toUpperCase();
    tagIndex = artist.artist.isNotEmpty
        ? (RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#')
        : '#';
  }

  @override
  String getSuspensionTag() => tagIndex;
}

class ArtistsView extends StatelessWidget {
  const ArtistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final artistBeans = controller.artists
          .map((artist) => ArtistBean(artist))
          .toList()
        ..sort((a, b) => a.artist.artist
            .toLowerCase()
            .compareTo(b.artist.artist.toLowerCase()));

      final tags =
          List.generate(26, (index) => String.fromCharCode(index + 65));

      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: AzListView(
          padding:
              const EdgeInsets.only(right: 40, left: 16, top: 16, bottom: 16),
          data: artistBeans,
          itemCount: artistBeans.length,
          indexBarItemHeight: MediaQuery.of(context).size.height / 38,
          itemBuilder: (context, index) {
            final artistBean = artistBeans[index];
            return ArtistCard(
              artist: artistBean.artist,
              isDarkMode: isDarkMode,
              onTap: () => Get.to(
                () => ArtistsDetailsView(artist: artistBean.artist),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 300),
              ),
            );
          },
          indexBarData: tags,
          indexBarOptions: IndexBarOptions(
            needRebuild: true,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withAlpha(204)
                  : Colors.grey[100]!.withAlpha(204),
              borderRadius: BorderRadius.circular(20),
            ),
            indexHintDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(197),
              shape: BoxShape.circle,
            ),
            indexHintAlignment: Alignment.centerRight,
            indexHintOffset: const Offset(-20, 0),
            indexHintTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textStyle: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white24 : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
            selectTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          physics: const BouncingScrollPhysics(),
        ),
      );
    });
  }
}

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final bool isDarkMode;
  final VoidCallback onTap;

  const ArtistCard({
    super.key,
    required this.artist,
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
                    id: artist.id,
                    type: ArtworkType.ARTIST,
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
                      artist.artist,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artist.numberOfTracks} songs',
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
