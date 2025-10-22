import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class SongDetails extends StatelessWidget {
  final SongModel currentSong;

  const SongDetails({super.key, required this.currentSong});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    String formatDuration(int raw) {
      // Treat raw as milliseconds
      Duration d = Duration(milliseconds: raw);

      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String minutes = twoDigits(d.inMinutes.remainder(60));
      String seconds = twoDigits(d.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    String songSize(int size) {
      int kb = 1024;
      double songSize = (size / (kb * kb));
      return songSize.toStringAsFixed(2);
    }

    String durationString = formatDuration(currentSong.duration ?? 0);
    String songSizeString = songSize(currentSong.size);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            // color: isDarkMode
            //     ? AppTheme.playerControlsLight
            //     : AppTheme.playerControlsDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Details',
          style: AppTheme.headlineMedium.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              /// Song Artwork and details would go here
              ///
              /// Song artwork
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: QueryArtworkWidget(
                    id: currentSong.id,
                    type: ArtworkType.AUDIO,
                    quality: 100,
                    size: 1000,
                    artworkQuality: FilterQuality.high,
                    nullArtworkWidget: Icon(
                      Iconsax.music,
                      size: 150,
                      // color: isDarkMode
                      //     ? AppTheme.playerControlsDark
                      //     : AppTheme.playerControlsLight,
                    ),
                  ),
                ),
              ),

              /// Horizontal Divider
              Divider(
                // color: isDarkMode
                //     ? AppTheme.playerControlsLight.withAlpha(80)
                //     : AppTheme.playerControlsDark,
                thickness: 1,
              ),

              /// Song title
              DetailsWidget(
                leftLabel: 'Title',
                rightLabel: currentSong.title,
              ),

              /// Artist name
              DetailsWidget(
                leftLabel: 'Artist',
                rightLabel: currentSong.artist ?? 'Unknown Artist',
              ),

              /// Album name
              DetailsWidget(
                leftLabel: 'Album',
                rightLabel: currentSong.album ?? 'Unknown Album',
              ),

              /// Song duration
              DetailsWidget(
                leftLabel: 'Duration',
                rightLabel: durationString,
              ),

              /// Song size
              DetailsWidget(
                leftLabel: 'File Size',
                rightLabel: '$songSizeString MB',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsWidget extends StatelessWidget {
  const DetailsWidget({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
  });

  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          leftLabel,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyMedium.copyWith(),
        ),
        Text(
          rightLabel,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyMedium.copyWith(),
        ),
      ],
    );
  }
}
