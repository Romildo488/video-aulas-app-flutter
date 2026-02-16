import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/video_model.dart';
import '../services/playlist_storage.dart';
import 'video_player_page.dart';

class PlaylistVideosPage extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistVideosPage({super.key, required this.playlist});

  @override
  State<PlaylistVideosPage> createState() => _PlaylistVideosPageState();
}

class _PlaylistVideosPageState extends State<PlaylistVideosPage> {
  final storage = PlaylistStorage();

  /// 🗑️ REMOVER VÍDEO DA PLAYLIST
  Future<void> removerVideo(VideoModel video) async {
    widget.playlist.videos.removeWhere((v) => v.url == video.url);

    final playlists = await storage.carregarPlaylists();

    final index = playlists.indexWhere((p) => p.nome == widget.playlist.nome);
    playlists[index] = widget.playlist;

    await storage.salvarPlaylists(playlists);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vídeo removido da playlist 🗑️")),
    );
  }

  /// ⭐ NOVO — abrir vídeo com autoplay da playlist
  void abrirVideoComAutoplay(VideoModel video, int index) {
    final urls = widget.playlist.videos.map((v) => v.url).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          url: video.url,
          playlistUrls: urls,
          playlistIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.nome)),
      body: widget.playlist.videos.isEmpty
          ? const Center(
        child: Text(
          "Nenhum vídeo na playlist 😢",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: widget.playlist.videos.length,
        itemBuilder: (context, index) {
          final video = widget.playlist.videos[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(video.titulo),

              /// ▶️ AGORA ABRE COM AUTOPLAY
              onTap: () => abrirVideoComAutoplay(video, index),

              /// 🗑️ REMOVER
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => removerVideo(video),
              ),
            ),
          );
        },
      ),
    );
  }
}
