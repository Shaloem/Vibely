import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
void main() {
  runApp(const VibelyApp());
}

// COLORS
const Color backgroundColor = Color(0xFF121212);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color purpleColor = Color(0xFF9B5DE5);
const Color secondaryTextColor = Color(0xFFAAAAAA);

// SAMPLE SONG DATA
final List<Map<String, dynamic>> songs = [
  {
    'id': '1',
    'title': 'Midnight Dreams',
    'artist': 'Luna Waves',
    'genre': 'Chill',
    'icon': Icons.nightlight_round,
    'audioPath': 'music/song1.mp3',
  },
  {
    'id': '2',
    'title': 'Golden Hour',
    'artist': 'Sunset Avenue',
    'genre': 'Pop',
    'icon': Icons.wb_sunny_rounded,
    'audioPath': 'music/song2.mp3',
  },
  {
    'id': '3',
    'title': 'Lost in Rhythm',
    'artist': 'Echo Beats',
    'genre': 'Electronic',
    'icon': Icons.graphic_eq_rounded,
  },
  {
    'id': '4',
    'title': 'Ocean Breeze',
    'artist': 'Blue Horizon',
    'genre': 'Relax',
    'icon': Icons.water_rounded,
  },
  {
    'id': '5',
    'title': 'Electric Nights',
    'artist': 'Neon Pulse',
    'genre': 'Electronic',
    'icon': Icons.bolt_rounded,
  },
  {
    'id': '6',
    'title': 'Dreamscape',
    'artist': 'Cloud Nine',
    'genre': 'Chill',
    'icon': Icons.cloud_rounded,
  },
];

// APP
class VibelyApp extends StatelessWidget {
  const VibelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: purpleColor,
          surface: surfaceColor,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// MAIN SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  String searchQuery = '';

  Set<String> favorites = {};

  Map<String, dynamic> currentSong = songs[0];

  bool isPlaying = false;

  // User-created playlists
  List<Map<String, dynamic>> userPlaylists = [];
  
  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();

    final playlistData = userPlaylists.map((playlist) {
      final playlistSongs =
          playlist['songs'] as List<Map<String, dynamic>>;

      return {
        'name': playlist['name'],
        'description': playlist['description'],
        'songIds': playlistSongs
            .map((song) => song['id'].toString())
            .toList(),
      };
    }).toList();

    final jsonString = jsonEncode(playlistData);

    await prefs.setString('vibely_playlists', jsonString);
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString('vibely_playlists');

    if (jsonString == null) {
      return;
    }

    final List<dynamic> decodedData = jsonDecode(jsonString);

    final loadedPlaylists = decodedData.map((item) {
      final songIds = List<String>.from(item['songIds']);

      final selectedSongs = songs
          .where((song) => songIds.contains(song['id'].toString()))
          .toList();

      return <String, dynamic>{
        'name': item['name'],
        'description': item['description'],
        'songs': selectedSongs,
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      userPlaylists = loadedPlaylists;
    });
  }

  final List<String> menuItems = [
    'Home',
    'Search',
    'Your Library',
    'Favorites',
  ];

  final List<IconData> menuIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.favorite_rounded,
  ];

  void toggleFavorite(String id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }
    });
  }

  
  // Actual audio player
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playSong(Map<String, dynamic> song) async {
    final audioPath = song['audioPath'];

    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio is not available for this song yet.'),
        ),
      );
      return;
    }

    setState(() {
      currentSong = song;
      isPlaying = true;
    });

    await audioPlayer.play(
      AssetSource(audioPath),
    );
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await audioPlayer.pause();

      setState(() {
        isPlaying = false;
      });
    } else {
      final audioPath = currentSong['audioPath'];

      if (audioPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio is not available for this song yet.'),
          ),
        );
        return;
      }

      await audioPlayer.play(
        AssetSource(audioPath),
    );

      setState(() {
        isPlaying = true;
      });
    }
  }


  Widget getCurrentScreen(bool isDesktop) {
    switch (selectedIndex) {
      case 0:
        return HomeContent(
          isDesktop: isDesktop,
          favorites: favorites,
          onFavorite: toggleFavorite,
          onPlay: playSong,
        );

      case 1:
        return SearchScreen(
          query: searchQuery,
          onQueryChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          favorites: favorites,
          onFavorite: toggleFavorite,
          onPlay: playSong,
        );

        
      case 2:
        return LibraryScreen(
          favorites: favorites,
          onFavorite: toggleFavorite,
          onPlay: playSong,
          userPlaylists: userPlaylists,

          onCreatePlaylist: (playlist) {
            setState(() {
              userPlaylists.add(playlist);
            });

            _savePlaylists();
          },

          onUpdatePlaylist: (index, playlist) {
            setState(() {
              userPlaylists[index] = playlist;
            });

            _savePlaylists();
          },

          onDeletePlaylist: (index) {
            setState(() {
              userPlaylists.removeAt(index);
            });

            _savePlaylists();
          },
        ); // <-- This closing line was missing!

      case 3:
        return FavoritesScreen(
          favorites: favorites,
          onFavorite: toggleFavorite,
          onPlay: playSong,
        );

      default:
        return const Center(child: Text('Page not found'));
    }
  }
  @override
  void dispose() {
  audioPlayer.dispose();
    super.dispose();
}
  @override
  void initState() {
    super.initState();

    _loadPlaylists();
}
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          body: Row(
            children: [
              if (isDesktop)
                NavigationSidebar(
                  selectedIndex: selectedIndex,
                  menuItems: menuItems,
                  menuIcons: menuIcons,
                  onItemSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),

              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: getCurrentScreen(isDesktop),
                    ),

                    MiniPlayer(
                      song: currentSong,
                      isPlaying: isPlaying,
                      onPlayPause: togglePlayPause,
                    ),
                  ],
                ),
              ),
            ],
          ),

          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  backgroundColor: surfaceColor,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  destinations: List.generate(
                    menuItems.length,
                    (index) => NavigationDestination(
                      icon: Icon(menuIcons[index]),
                      label: menuItems[index],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// SIDEBAR
class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<String> menuItems;
  final List<IconData> menuIcons;
  final Function(int) onItemSelected;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.menuItems,
    required this.menuIcons,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: surfaceColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.music_note_rounded,
                  color: purpleColor, size: 36),
              SizedBox(width: 8),
              Text(
                'Vibely',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          const Text(
            'MENU',
            style: TextStyle(
              color: secondaryTextColor,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          ...List.generate(
            menuItems.length,
            (index) => ListTile(
              selected: selectedIndex == index,
              selectedTileColor: purpleColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(
                menuIcons[index],
                color: selectedIndex == index
                    ? purpleColor
                    : secondaryTextColor,
              ),
              title: Text(menuItems[index]),
              onTap: () => onItemSelected(index),
            ),
          ),

          const Spacer(),

          const Text(
            'Made with Flutter 💜',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// HOME DASHBOARD
class HomeContent extends StatelessWidget {
  final bool isDesktop;
  final Set<String> favorites;
  final Function(String) onFavorite;
  final Function(Map<String, dynamic>) onPlay;

  const HomeContent({
    super.key,
    required this.isDesktop,
    required this.favorites,
    required this.onFavorite,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good evening 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Discover your next favorite song.',
            style: TextStyle(color: secondaryTextColor),
          ),

          const SizedBox(height: 32),

          const FeaturedCard(),

          const SizedBox(height: 32),

          const Text(
            'Your Playlists',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: const [
              PlaylistCard(
                title: 'Chill Vibes',
                icon: Icons.nightlight_round,
                color: Color(0xFF6C63FF),
              ),
              PlaylistCard(
                title: 'Workout Hits',
                icon: Icons.fitness_center,
                color: Color(0xFFFF6B6B),
              ),
              PlaylistCard(
                title: 'Daily Mix',
                icon: Icons.headphones_rounded,
                color: Color(0xFF00B894),
              ),
              PlaylistCard(
                title: 'Acoustic',
                icon: Icons.music_note_rounded,
                color: Color(0xFFFFB142),
              ),
            ],
          ),

          const SizedBox(height: 32),

          const Text(
            'Recently Played',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...songs.take(3).map(
                (song) => SongTile(
                  song: song,
                  isFavorite: favorites.contains(song['id']),
                  onFavorite: () => onFavorite(song['id']),
                  onPlay: () => onPlay(song),
                ),
              ),
        ],
      ),
    );
  }
}

// SEARCH SCREEN
class SearchScreen extends StatelessWidget {
  final String query;
  final Function(String) onQueryChanged;
  final Set<String> favorites;
  final Function(String) onFavorite;
  final Function(Map<String, dynamic>) onPlay;

  const SearchScreen({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.favorites,
    required this.onFavorite,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSongs = songs.where((song) {
      final title = song['title'].toString().toLowerCase();
      final artist = song['artist'].toString().toLowerCase();

      return title.contains(query.toLowerCase()) ||
          artist.contains(query.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Music',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search songs or artists...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: filteredSongs.isEmpty
                ? const Center(
                    child: Text(
                      'No songs found.',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];

                      return SongTile(
                        song: song,
                        isFavorite: favorites.contains(song['id']),
                        onFavorite: () => onFavorite(song['id']),
                        onPlay: () => onPlay(song),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// LIBRARY SCREEN

class LibraryScreen extends StatelessWidget {
  final Set<String> favorites;
  final Function(String) onFavorite;
  final Function(Map<String, dynamic>) onPlay;

  final List<Map<String, dynamic>> userPlaylists;
  final Function(Map<String, dynamic>) onCreatePlaylist;
  final Function(int, Map<String, dynamic>) onUpdatePlaylist;
  final Function(int) onDeletePlaylist;

  const LibraryScreen({
    super.key,
    required this.favorites,
    required this.onFavorite,
    required this.onPlay,
    required this.userPlaylists,
    required this.onCreatePlaylist,
    required this.onUpdatePlaylist,
    required this.onDeletePlaylist,
  });

  Future<void> _showPlaylistDialog(
    BuildContext context, {
    Map<String, dynamic>? initialPlaylist,
    int? playlistIndex,
  }) async {
    final playlist = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return CreatePlaylistDialog(
          initialPlaylist: initialPlaylist,
        );
      },
    );

    if (playlist != null) {
      if (playlistIndex == null) {
        onCreatePlaylist(playlist);
      } else {
        onUpdatePlaylist(playlistIndex, playlist);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    int index,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          title: const Text('Delete Playlist?'),
          content: Text(
            'Are you sure you want to delete '
            '"${userPlaylists[index]['name']}"? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      onDeletePlaylist(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showPlaylistDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Playlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purpleColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Your music collection and personal playlists.',
            style: TextStyle(color: secondaryTextColor),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              children: [
                const Text(
                  'My Playlists',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (userPlaylists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No playlists created yet.\n'
                      'Click Create Playlist to get started!',
                      style: TextStyle(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),

                ...userPlaylists.asMap().entries.map((entry) {
                  final index = entry.key;
                  final playlist = entry.value;

                  final playlistSongs =
                      playlist['songs'] as List<Map<String, dynamic>>;

                  return Card(
                    color: surfaceColor,
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.queue_music_rounded,
                        color: purpleColor,
                      ),

                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              playlist['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: 'Edit Playlist',
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: purpleColor,
                            ),
                            onPressed: () {
                              _showPlaylistDialog(
                                context,
                                initialPlaylist: playlist,
                                playlistIndex: index,
                              );
                            },
                          ),

                          IconButton(
                            tooltip: 'Delete Playlist',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              _confirmDelete(context, index);
                            },
                          ),
                        ],
                      ),

                      subtitle: Text(
                        '${playlistSongs.length} songs • '
                        '${playlist['description']}',
                      ),

                      children: playlistSongs.map((song) {
                        return ListTile(
                          leading: Icon(
                            song['icon'],
                            color: purpleColor,
                          ),
                          title: Text(song['title']),
                          subtitle: Text(song['artist']),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: purpleColor,
                            ),
                            onPressed: () => onPlay(song),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                const Text(
                  'All Songs',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...songs.map((song) {
                  return SongTile(
                    song: song,
                    isFavorite: favorites.contains(song['id']),
                    onFavorite: () => onFavorite(song['id']),
                    onPlay: () => onPlay(song),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// FAVORITES SCREEN
class FavoritesScreen extends StatelessWidget {
  final Set<String> favorites;
  final Function(String) onFavorite;
  final Function(Map<String, dynamic>) onPlay;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onFavorite,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteSongs = songs
        .where((song) => favorites.contains(song['id']))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorites ❤️',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your favorite tracks in one place.',
            style: TextStyle(color: secondaryTextColor),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: favoriteSongs.isEmpty
                ? const Center(
                    child: Text(
                      'No favorites yet.\nTap the heart on a song to add it!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: favoriteSongs.length,
                    itemBuilder: (context, index) {
                      final song = favoriteSongs[index];

                      return SongTile(
                        song: song,
                        isFavorite: true,
                        onFavorite: () => onFavorite(song['id']),
                        onPlay: () => onPlay(song),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// FEATURED CARD
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7B2FF7),
            Color(0xFF4C1D95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FEATURED PLAYLIST',
            style: TextStyle(letterSpacing: 2),
          ),

          const SizedBox(height: 16),

          const Text(
            'Feel the Music',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text('Your daily dose of good vibes.'),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Explore Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: purpleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// PLAYLIST CARD
class PlaylistCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const PlaylistCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color,
                ),
                child: Icon(
                  icon,
                  size: 55,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// SONG TILE
class SongTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onPlay;

  const SongTile({
    super.key,
    required this.song,
    required this.isFavorite,
    required this.onFavorite,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),

      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: purpleColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          song['icon'],
          color: purpleColor,
        ),
      ),

      title: Text(
        song['title'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle: Text(
        song['artist'],
        style: const TextStyle(color: secondaryTextColor),
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: isFavorite ? Colors.red : secondaryTextColor,
            ),
          ),

          IconButton(
            onPressed: onPlay,
            icon: const Icon(Icons.play_circle_fill_rounded),
            color: purpleColor,
          ),
        ],
      ),
    );
  }
}

// MINI PLAYER
class MiniPlayer extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.music_note_rounded,
            color: purpleColor,
            size: 32,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                Text(
                  song['artist'],
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onPlayPause,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill_rounded,
            ),
            color: purpleColor,
            iconSize: 36,
          ),
        ],
      ),
    );
  }
}

// CREATE PLAYLIST DIALOG
// CREATE / EDIT PLAYLIST DIALOG
class CreatePlaylistDialog extends StatefulWidget {
  final Map<String, dynamic>? initialPlaylist;

  const CreatePlaylistDialog({
    super.key,
    this.initialPlaylist,
  });

  @override
  State<CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}
class _CreatePlaylistDialogState
    extends State<CreatePlaylistDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  Set<String> selectedSongIds = {};
  @override
  void initState() {
    super.initState();

    final playlist = widget.initialPlaylist;

    if (playlist != null) {
      nameController.text = playlist['name'] ?? '';

      descriptionController.text =
          playlist['description'] ?? '';

      final existingSongs =
          playlist['songs'] as List<Map<String, dynamic>>;

      selectedSongIds = existingSongs
          .map((song) => song['id'].toString())
          .toSet();
    }
  }
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void savePlaylist() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedSongIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one song.'),
        ),
      );

      return;
    }

    final selectedSongs = songs
        .where((song) => selectedSongIds.contains(song['id']))
        .toList();

    final playlist = <String, dynamic>{
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'songs': selectedSongs,
    };

    Navigator.of(context).pop(playlist);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surfaceColor,

      title: Text(
        widget.initialPlaylist == null
        ? 'Create Playlist 🎵'
        : 'Edit Playlist ✏️',
        style: const TextStyle(
        fontWeight: FontWeight.bold,
  ),
),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PLAYLIST NAME
                TextFormField(
                  controller: nameController,

                  decoration: InputDecoration(
                    labelText: 'Playlist Name',
                    hintText: 'e.g. My Favorite Songs',
                    prefixIcon: const Icon(
                      Icons.queue_music_rounded,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a playlist name.';
                    }

                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // DESCRIPTION
                TextFormField(
                  controller: descriptionController,

                  maxLines: 2,

                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your playlist...',
                    prefixIcon: const Icon(
                      Icons.description_rounded,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Select Songs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // SONG SELECTION
                ...songs.map((song) {
                  final songId = song['id'].toString();

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,

                    activeColor: purpleColor,

                    value: selectedSongIds.contains(songId),

                    title: Text(song['title']),

                    subtitle: Text(song['artist']),

                    secondary: Icon(
                      song['icon'],
                      color: purpleColor,
                    ),

                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedSongIds.add(songId);
                        } else {
                          selectedSongIds.remove(songId);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },

          child: const Text(
            'Cancel',
            style: TextStyle(
              color: secondaryTextColor,
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: savePlaylist,

          icon: const Icon(Icons.check_rounded),

          label: Text(
          widget.initialPlaylist == null
          ? 'Create'
          : 'Save Changes',
),

          style: ElevatedButton.styleFrom(
            backgroundColor: purpleColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}