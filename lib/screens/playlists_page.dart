import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../services/playlist_storage.dart';
import 'playlist_videos_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final storage = PlaylistStorage();
  List<PlaylistModel> playlists = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    playlists = await storage.carregarPlaylists();
    setState(() {});
  }

  Future<void> criarPlaylist() async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nova Playlist"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text("Criar"),
            onPressed: () async {
              playlists.add(PlaylistModel(nome: controller.text, videos: []));
              await storage.salvarPlaylists(playlists);
              Navigator.pop(context);
              carregar();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Playlists")),
      floatingActionButton: FloatingActionButton(
        onPressed: criarPlaylist,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: playlists.map((playlist) {
          return ListTile(
            title: Text(playlist.nome),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistVideosPage(playlist: playlist),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
