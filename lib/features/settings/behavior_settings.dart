import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/settings/folder_blacklist.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';

class BehaviorSettingsScreen extends StatefulWidget {
  const BehaviorSettingsScreen({super.key});

  @override
  State<BehaviorSettingsScreen> createState() => _BehaviorSettingsScreenState();
}

class _BehaviorSettingsScreenState extends State<BehaviorSettingsScreen> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final TextEditingController _lengthController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMinSongLength();
    _lengthController.addListener(_onTextChanged);
  }

  Future<void> _loadMinSongLength() async {
    final minLength = await getMinSongLength();
    _lengthController.text = minLength.toString();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final newLength = int.tryParse(_lengthController.text) ?? 0;
      await saveMinSongLength(newLength);
      await _playerController.refreshSongs();
    });
  }

  @override
  void dispose() {
    _lengthController.removeListener(_onTextChanged);
    _lengthController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Minimum Song Length'),
            subtitle: const Text('Exclude songs shorter than this duration (in seconds).'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _lengthController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Iconsax.folder_minus),
            title: const Text('Folder Blacklist'),
            subtitle: const Text('Exclude songs from specific folders.'),
            onTap: () {
              Get.to(() => const FolderBlacklistScreen());
            },
          ),
        ],
      ),
    );
  }
}
