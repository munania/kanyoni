import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'artists_card.dart';
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

class ArtistsView extends StatefulWidget {
  const ArtistsView({super.key});

  @override
  State<ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends State<ArtistsView> {
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  late ArtistController artistController;

  @override
  void initState() {
    super.initState();
    artistController = Get.find<ArtistController>();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    if (artistController.shouldRestoreScrollPosition()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.jumpTo(
          index: (artistController.listScrollOffset.value / 100).floor(),
        );
      });
    }

    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstItem = positions.first;
      artistController.updateListScrollPosition(firstItem.index * 100.0);
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final artistBeans = artistController.artists
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
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
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
