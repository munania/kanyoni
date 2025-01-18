// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/artists/artists.dart';
import 'package:kanyoni/features/playlists/playlists.dart';
import 'package:kanyoni/utils/theme/theme.dart';

import 'features/albums/album.dart';
import 'features/genres/genres.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        view: const PlaylistView(),
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
      elevation: 0,
      title: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {}, // TODO: Implement search
              child: const Icon(Iconsax.search_favorite_1),
            ),
          ],
        ),
      ),
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
