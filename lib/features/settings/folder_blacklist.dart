import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class FolderBlacklistScreen extends StatefulWidget {
  const FolderBlacklistScreen({super.key});

  @override
  State<FolderBlacklistScreen> createState() => _FolderBlacklistScreenState();
}

class _FolderBlacklistScreenState extends State<FolderBlacklistScreen> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final FolderController _folderController = Get.find<FolderController>();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<String> _allFolders = [];
  List<String> _blacklistedFolders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allFolders = await _audioQuery.queryAllPath();
    final blacklistedFolders = await getBlacklistedFolders();
    setState(() {
      _allFolders = allFolders;
      _blacklistedFolders = blacklistedFolders;
      _isLoading = false;
    });
  }

  Future<void> _onCheckboxChanged(bool? value, String folderPath) async {
    setState(() {
      if (value == true) {
        _blacklistedFolders.add(folderPath);
      } else {
        _blacklistedFolders.remove(folderPath);
      }
    });
    await saveBlacklistedFolders(_blacklistedFolders);
    await _playerController.refreshSongs();
    await _folderController.fetchFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Blacklist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allFolders.length,
              itemBuilder: (context, index) {
                final folderPath = _allFolders[index];
                final isBlacklisted = _blacklistedFolders.contains(folderPath);
                return CheckboxListTile(
                  title: Text(folderPath),
                  value: isBlacklisted,
                  onChanged: (bool? value) {
                    _onCheckboxChanged(value, folderPath);
                  },
                );
              },
            ),
    );
  }
}
