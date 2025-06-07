// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart'; // Added
import 'package:kanyoni/features/about/about.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart'; // Added
import 'package:kanyoni/features/artists/controller/artists_controller.dart'; // Added
import 'package:kanyoni/features/artists/artists.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart'; // Added
import 'package:kanyoni/features/folders/folders.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart'; // Added
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart'; // Added
import 'package:kanyoni/features/playlists/playlists.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';

import 'features/albums/album.dart';
import 'features/genres/genres.dart';
import 'features/search/search.dart';
import 'features/settings/settings.dart';
import 'features/tracks/tracks.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadInitialData();
  }

  void _loadInitialData() {
    Get.find<PlayerController>().fetchAllSongs();
    Get.find<PlaylistController>().fetchPlaylists();
    Get.find<AlbumController>().fetchAlbums();
    Get.find<ArtistController>().fetchArtists();
    Get.find<GenreController>().fetchGenres();
    Get.find<FolderController>().fetchFolders();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final backgroundColor =
        isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight;

    final List<TabData> tabs = [
      TabData(
        title: 'Tracks',
        view: const TracksView(),
      ),
      TabData(
        title: 'Playlists',
        view: const PlaylistView(),
      ),
      TabData(
        title: 'Albums',
        view: const AlbumsView(),
      ),
      TabData(
        title: 'Artists',
        view: const ArtistsView(),
      ),
      TabData(
        title: 'Genres',
        view: const GenreView(),
      ),
      TabData(
        title: 'Folders',
        view: const FoldersView(),
      ),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(tabs),
          Expanded(
            child: Container(
              color: backgroundColor,
              // Add padding at the bottom to account for the collapsed player
              padding: const EdgeInsets.only(bottom: 70),
              child: TabBarView(
                controller: _tabController,
                children: tabs.map((tab) => tab.view).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child:
            Text("Kanyoni", style: Theme.of(context).textTheme.headlineSmall),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Iconsax.search_normal),
                onPressed: () {
                  Get.to(() => const SearchView());
                },
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      Get.to(() => const SettingsView());
                      break;
                    case 'about':
                      Get.to(() => AboutView());
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: const Row(
                      children: [
                        Icon(Iconsax.setting_2),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Iconsax.info_circle),
                        SizedBox(width: 8),
                        Text('About Kanyoni'),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTabBar(List<TabData> tabs) {
    return SizedBox(
      height: kToolbarHeight - 15,
      child: TabBar(
        controller: _tabController,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
        isScrollable: true,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
      ),
    );
  }
}

class TabData {
  final String title;
  final Widget view;

  const TabData({
    required this.title,
    required this.view,
  });
}
