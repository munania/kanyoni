// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/about/about.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';
import 'package:kanyoni/features/artists/artists.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:kanyoni/features/favorites/favorites_view.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/features/folders/folders.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:kanyoni/features/playlists/playlists.dart';

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

  // Define tabs as a constant list
  static const List<TabData> _tabs = [
    TabData(title: 'Tracks', icon: Iconsax.music),
    TabData(title: 'Favorites', icon: Iconsax.heart),
    TabData(title: 'Playlists', icon: Iconsax.music_playlist),
    TabData(title: 'Albums', icon: Iconsax.heart_add),
    TabData(title: 'Artists', icon: Iconsax.microphone),
    TabData(title: 'Genres', icon: Iconsax.music_filter),
    TabData(title: 'Folders', icon: Iconsax.folder_2),
  ];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Use try-catch to handle potential controller not found errors
    try {
      Get.find<PlayerController>().fetchAllSongs();
      Get.find<PlaylistController>().fetchPlaylists();
      Get.find<AlbumController>().fetchAlbums();
      Get.find<ArtistController>().fetchArtists();
      Get.find<GenreController>().fetchGenres();
      Get.find<FolderController>().fetchFolders();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _initializeTabController() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: TabBarView(
                controller: _tabController,
                children: _buildTabViews(),
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
        child: Text(
          "Kanyoni",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      actions: [
        _buildSearchButton(),
        _buildMenuButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Iconsax.search_normal),
      tooltip: 'Search',
      onPressed: () => Get.to(() => const SearchView()),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'More options',
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        _buildMenuItem(
          value: 'settings',
          icon: Iconsax.setting_2,
          label: 'Settings',
        ),
        _buildMenuItem(
          value: 'about',
          icon: Iconsax.info_circle,
          label: 'About Kanyoni',
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Get.to(() => const SettingsView());
        break;
      case 'about':
        Get.to(() => const AboutView());
        break;
    }
  }

  Widget _buildTabBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context).primaryColor.withValues(alpha: 0.05);
            }
            if (states.contains(WidgetState.pressed)) {
              return Theme.of(context).primaryColor.withValues(alpha: 0.1);
            }
            return null;
          },
        ),
        tabs: _tabs.map((tab) {
          final isSelected = _tabController.index == _tabs.indexOf(tab);
          return Tab(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      tab.icon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(tab.title),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTabViews() {
    return const [
      TracksView(),
      FavoritesView(),
      PlaylistView(),
      AlbumsView(),
      ArtistsView(),
      GenreView(),
      FoldersView(),
    ];
  }
}

class TabData {
  final String title;
  final IconData icon;

  const TabData({
    required this.title,
    required this.icon,
  });
}
