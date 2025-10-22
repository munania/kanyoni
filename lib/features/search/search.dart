import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/now_playing.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final PlayerController playerController = Get.find<PlayerController>();
  final PanelController panelController = PanelController();
  final TextEditingController _searchController = TextEditingController();
  final RxList<SongModel> _filteredSongs = <SongModel>[].obs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    playerController.currentPlaylist.value = playerController.songs;
    super.dispose();
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      _filteredSongs.value = playerController.songs;
    } else {
      _filteredSongs.value = playerController.songs
          .where((song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              (song.artist?.toLowerCase() ?? '').contains(query.toLowerCase()))
          .toList();
    }
  }

  void _playFromSearch(SongModel song) {
    //update the current playlist to the filtered songs
    playerController.currentPlaylist.value = _filteredSongs;

    //Find the index of the song in the filtered list
    final index = _filteredSongs.indexWhere((s) => s.id == song.id);

    // Play the selected song
    if (index != -1) {
      playerController.playSong(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Important: only on the root Scaffold
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 80,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: playerController,
        ),
        collapsed: CollapsedPanel(
          panelController: panelController,
          playerController: playerController,
        ),
        body: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: TextField(
                  autofocus: true,
                  controller: _searchController,
                  onChanged: _filterSongs,
                  decoration: const InputDecoration(
                    hintText: 'Search songs...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Iconsax.search_normal),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return ListTile(
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Icon(
                            Iconsax.music,
                            size: 50,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: AppTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist ?? 'Unknown Artist',
                          style: AppTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _playFromSearch(song),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
