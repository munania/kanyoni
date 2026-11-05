# Kanyoni 🎵

Kanyoni is a modern, feature-rich offline music player built with Flutter. It combines a sleek glassmorphic design with powerful audio capabilities to provide an immersive listening experience.

## ✨ Features

- **Offline Playback**: Scan and play your local music library with ease.
- **Modern UI**: Beautiful glassmorphism design with dynamic theming support.
- **Lyrics Support**: Synchronized or static lyrics, matched to your exact file (by title, artist and length), cached offline, with per-song sync adjustment and tap-to-seek.
- **Playlists**: Create, manage, and customize your own playlists.
- **Equalizer**: Fine-tune your audio with a built-in equalizer.
- **Visualizer**: Dynamic audio waveforms for a visual music experience.
- **Favorites**: Quickly mark and access your favorite tracks.
- **Search**: Fast and efficient search for songs, artists, and albums.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio)
- **Local Database**: [Hive](https://pub.dev/packages/hive) (lyrics cache; opened lazily so it doesn't affect start-up)
- **UI Components**: Custom glassmorphic widgets, [sliding_up_panel](https://pub.dev/packages/sliding_up_panel)

## 🚀 Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/munania/kanyoni.git
   cd kanyoni
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Generate app icons (optional):**

   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the app:**

   ```bash
   flutter run
   ```

## 📱 Platform support

Kanyoni currently targets **Android**. Music scanning (MediaStore) and the equalizer rely on Android-only plugins; the other platform folders are Flutter scaffolding and are not supported yet.

## 🧪 Tests

```bash
flutter test
```

Unit tests cover the LRC parser, the lyrics matching logic and the folder filters.

## 📝 To-Do

- [ ] Gapless playback (needs a playlist-based audio source)
- [ ] Add screenshots to this README

## 🤝 Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.
