import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import 'video_player_page.dart';

class PlaylistVideosPage extends StatelessWidget {
  final PlaylistModel playlist;
  const PlaylistVideosPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(playlist.nome)),
      body: ListView(
        children: playlist.videos.map((video) {
          return ListTile(
            title: Text(video.titulo),
            leading: const Icon(Icons.play_circle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerPage(url: video.url),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
