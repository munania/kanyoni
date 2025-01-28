import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../artists/controller/artists_controller.dart';
import 'genre_card.dart';
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

class GenreView extends StatefulWidget {
  const GenreView({super.key});

  @override
  State<StatefulWidget> createState() => _GenreViewState();
}

class _GenreViewState extends State<GenreView> {
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;
  late ArtistController genreController;

  @override
  void initState() {
    super.initState();
    genreController = Get.find<ArtistController>();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    if (genreController.shouldRestoreScrollPosition()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.jumpTo(
          index: (genreController.listScrollOffset.value / 100).floor(),
        );
      });
    }

    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstItem = positions.first;
      genreController.updateListScrollPosition(firstItem.index * 100.0);
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genreController = Get.find<GenreController>();
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
      final genreBeans = genreController.genres
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
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
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
