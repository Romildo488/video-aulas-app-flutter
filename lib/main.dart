import 'services/firestore_service.dart';
import 'services/local_video_service.dart';
import 'services/local_videos_storage.dart';
import 'services/thumbnail_service.dart';
import 'services/video_download_service.dart'; // ⭐ NOVO DOWNLOAD
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/playlists_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/videos_data.dart';
import 'models/video_model.dart';
import 'screens/video_player_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minhas Video Aulas',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomePage();
        return const LoginPage();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, int> progressoVideos = {};
  final firestore = FirestoreService();
  final localVideo = LocalVideoService();
  final storage = LocalVideosStorage();
  final thumbService = ThumbnailService();
  final downloader = VideoDownloadService(); // ⭐ NOVO

  List<VideoModel> videosLocais = [];

  String formatarTempo(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void initState() {
    super.initState();
    carregarVideosLocais();
    carregarProgresso();
  }

  Future<void> carregarVideosLocais() async {
    videosLocais = await storage.carregarVideos();
    setState(() {});
  }

  Future<void> deletarVideoLocal(VideoModel video) async {
    videosLocais.removeWhere((v) => v.url == video.url);
    await storage.salvarVideos(videosLocais);
    setState(() {});
  }

  Future<void> carregarProgresso() async {
    final prefs = await SharedPreferences.getInstance();
    for (var video in [...listaVideos, ...videosLocais]) {
      progressoVideos[video.url] = prefs.getInt(video.url) ?? 0;
    }
    setState(() {});
  }

  Future<void> adicionarVideoLocal() async {
    final path = await localVideo.escolherVideo();
    if (path == null) return;

    final thumbPath = await thumbService.gerarThumbnail(path);

    final novoVideo = VideoModel(
      titulo: "Minha aula ${videosLocais.length + 1}",
      url: path,
      thumbnail: thumbPath ?? "",
      isLocal: true,
    );

    videosLocais.add(novoVideo);
    await storage.salvarVideos(videosLocais);
    await carregarProgresso();
    setState(() {});
  }

  ////////////////////////////////////////////////////////////////
  /// ⭐ NOVO DOWNLOAD DE VIDEO
  Future<void> baixarVideo(VideoModel video) async {
    if (video.isLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vídeo já está baixado 📱")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Baixando vídeo... ⏬")),
    );

    final path = await downloader.baixarVideo(
      video.url,
      video.titulo.replaceAll(" ", "_"),
    );


    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao baixar vídeo ❌")),
      );
      return;
    }

    final thumbPath = await thumbService.gerarThumbnail(path);

    final novoVideo = VideoModel(
      titulo: video.titulo,
      url: path,
      thumbnail: thumbPath ?? "",
      isLocal: true,
    );

    videosLocais.add(novoVideo);
    await storage.salvarVideos(videosLocais);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Download concluído 🎉")),
    );
  }

  ////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Video Aulas 🎓"),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlaylistsPage(videoParaAdicionar: null)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text("Adicionar aula do celular"),
              onPressed: adicionarVideoLocal,
            ),
          ),
          ...videosLocais
              .map((v) => _buildVideoCard(v, progressoVideos[v.url] ?? 0)),
          ...listaVideos
              .map((v) => _buildVideoCard(v, progressoVideos[v.url] ?? 0)),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////////
  /// ⭐ CARD COM BOTÃO DOWNLOAD ADICIONADO
  Widget _buildVideoCard(VideoModel video, int segundosAssistidos) {
    const int duracaoTotal = 180;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(url: video.url)),
            );
            carregarProgresso();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: video.thumbnail.startsWith("/")
                        ? Image.file(File(video.thumbnail),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover)
                        : Image.network(video.thumbnail,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatarTempo(duracaoTotal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(video.titulo,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  /// ⭐ BOTÃO DOWNLOAD
                  IconButton(
                    icon: Icon(
                      video.isLocal ? Icons.download_done : Icons.download,
                      color: Colors.green,
                    ),
                    onPressed: () => baixarVideo(video),
                  ),

                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaylistsPage(videoParaAdicionar: video),
                        ),
                      );
                    },
                  ),

                  if (video.isLocal)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deletarVideoLocal(video),
                    ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
