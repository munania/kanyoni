import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        _buildAppBar(isDarkMode),
        _buildHeaderSection(isDarkMode),
      ],
    ));
  }
}

SliverAppBar _buildAppBar(bool isDarkMode) {
  return SliverAppBar(
    expandedHeight: 300,
    pinned: true,
    flexibleSpace: FlexibleSpaceBar(
      centerTitle: true,
      title: Text(
        "About Kanyoni",
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      // background: Image.asset('assets/images/kanyoni.png'),
      background: Icon(Iconsax.global, size: 70),
    ),
  );
}

SliverToBoxAdapter _buildHeaderSection(bool isDarkMode) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Kanyoni is a music player app that is built with Flutter and GetX. It is a simple music player that allows you to play music from your device.",
            style: AppTheme.bodyMedium.copyWith(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
