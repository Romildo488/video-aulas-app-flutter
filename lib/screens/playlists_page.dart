import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../services/playlist_storage.dart';
import 'playlist_videos_page.dart';
import '../models/video_model.dart';

class PlaylistsPage extends StatefulWidget {
  final VideoModel? videoParaAdicionar;

  const PlaylistsPage({
    super.key,
    this.videoParaAdicionar,
  });

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

  /// ⭐ ADICIONAR VIDEO NA PLAYLIST
  Future<void> adicionarVideoNaPlaylist(PlaylistModel playlist) async {
    final video = widget.videoParaAdicionar;
    if (video == null) return;

    bool jaExiste = playlist.videos.any((v) => v.url == video.url);
    if (jaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esse vídeo já está na playlist")),
      );
      return;
    }

    playlist.videos.add(video);
    await storage.salvarPlaylists(playlists);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Vídeo adicionado à playlist ${playlist.nome} 🎉")),
    );

    Navigator.pop(context);
  }

  /// ⭐ NOVO → APAGAR PLAYLIST
  Future<void> apagarPlaylist(PlaylistModel playlist) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir playlist"),
        content: Text("Deseja apagar a playlist '${playlist.nome}' ?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    playlists.removeWhere((p) => p.nome == playlist.nome);
    await storage.salvarPlaylists(playlists);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Playlist apagada 🗑️")),
    );
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
    bool modoAdicionar = widget.videoParaAdicionar != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(modoAdicionar ? "Adicionar à playlist" : "Playlists"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: criarPlaylist,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: playlists.map((playlist) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(playlist.nome),

              /// TRAILING DINÂMICO
              trailing: modoAdicionar
                  ? const Icon(Icons.playlist_add)
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => apagarPlaylist(playlist),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),

              onTap: () {
                if (modoAdicionar) {
                  adicionarVideoNaPlaylist(playlist);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistVideosPage(playlist: playlist),
                    ),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
