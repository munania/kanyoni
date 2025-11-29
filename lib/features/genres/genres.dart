import 'dart:ui';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'genre_card.dart';
import 'genre_details.dart';
import 'genre_grid_card.dart';

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

class HeaderBean extends ISuspensionBean {
  @override
  String getSuspensionTag() => "!";
}

class GenreView extends StatefulWidget {
  const GenreView({super.key});

  @override
  State<StatefulWidget> createState() => _GenreViewState();
}

class _GenreViewState extends State<GenreView>
    with AutomaticKeepAliveClientMixin {
  late GenreController genreController;
  bool _isGridView = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    genreController = Get.find<GenreController>();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('genres_grid_view') ?? false;
    });
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool('genres_grid_view', _isGridView);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final PlayerController playerController = Get.find();

    return Scaffold(
      body: Obx(() {
        // Get current song for background artwork
        final currentSongIndex = playerController.currentSongIndex.value;
        final hasCurrentSong = currentSongIndex >= 0 &&
            currentSongIndex < playerController.currentPlaylist.length;
        final currentSong = hasCurrentSong
            ? playerController.currentPlaylist[currentSongIndex]
            : null;

        final genreBeans = genreController.genres
            .map((genre) => GenreBean(genre))
            .toList()
          ..sort((a, b) => a.genre.genre
              .toLowerCase()
              .compareTo(b.genre.genre.toLowerCase()));

        final List<ISuspensionBean> azItems = [];
        if (!_isGridView) {
          azItems.add(HeaderBean());
          azItems.addAll(genreBeans);
        }

        final tags =
            List.generate(26, (index) => String.fromCharCode(index + 65));

        return Stack(
          children: [
            // Background Artwork with Blur
            RepaintBoundary(
              child: Stack(
                children: [
                  if (currentSong != null)
                    Positioned.fill(
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        quality: 100,
                        size: 1000,
                        artworkQuality: FilterQuality.high,
                        nullArtworkWidget: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ThemedArtworkPlaceholder(
                        iconSize: 120,
                      ),
                    ),
                  // Blur Effect
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(
                                alpha: isDarkMode ? 0.7 : 0.85,
                              ),
                          child: Container(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (genreController.genres.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.music_filter,
                      size: 80,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Genres Found',
                      style: AppTheme.headlineMedium.copyWith(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your music genres will appear here',
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isGridView)
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildToggleButton(context, isDarkMode),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final genreBean = genreBeans[index];
                          return GenreGridCard(
                            genre: genreBean.genre,
                            onTap: () => Get.to(
                              () => GenreDetailsView(genre: genreBean.genre),
                              transition: Transition.cupertino,
                              duration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        childCount: genreBeans.length,
                      ),
                    ),
                  )
                ],
              )
            else
              Column(
                children: [
                  Expanded(
                    child: AzListView(
                      padding: const EdgeInsets.only(right: 48, left: 16),
                      data: azItems,
                      itemCount: azItems.length,
                      indexBarWidth: 36,
                      indexBarItemHeight: 22,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = azItems[index];
                        if (item is HeaderBean) {
                          return _buildToggleButton(context, isDarkMode);
                        }
                        final genreBean = item as GenreBean;
                        return GenreCard(
                          genre: genreBean.genre,
                          onTap: () => Get.to(
                            () => GenreDetailsView(genre: genreBean.genre),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      indexBarData: tags,
                      indexBarOptions: IndexBarOptions(
                        needRebuild: true,
                        // Modern sleek design
                        decoration: BoxDecoration(
                          color: (isDarkMode ? Colors.grey[900] : Colors.white)
                              ?.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDarkMode ? 0.3 : 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        // Hint bubble styling
                        indexHintDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        indexHintAlignment: Alignment.centerRight,
                        indexHintOffset: const Offset(-56, 0),
                        indexHintTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        // Index bar text styling
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        selectTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }

  Widget _buildToggleButton(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleView,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isGridView
                            ? Iconsax.row_horizontal
                            : Iconsax.element_4,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isGridView ? 'List' : 'Grid',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
