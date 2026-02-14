import 'services/firestore_service.dart';
import 'services/local_video_service.dart';
import 'services/local_videos_storage.dart';
import 'services/thumbnail_service.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/playlists_page.dart'; // ⭐ NOVO
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
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
            body: Center(child: CircularProgressIndicator()),
          );
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

  List<VideoModel> videosLocais = [];

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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Aula removida 🗑️")));
  }

  Future<void> carregarProgresso() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> progressoLocal = {};

    for (var video in [...listaVideos, ...videosLocais]) {
      progressoLocal[video.url] = prefs.getInt(video.url) ?? 0;
    }

    Map<String, int> progressoNuvem = {};
    try {
      progressoNuvem = await firestore.carregarProgresso();
    } catch (e) {}

    for (var video in [...listaVideos, ...videosLocais]) {
      int local = progressoLocal[video.url] ?? 0;
      int nuvem = progressoNuvem[video.url] ?? 0;
      int maior = local > nuvem ? local : nuvem;

      progressoVideos[video.url] = maior;
      await prefs.setInt(video.url, maior);

      try {
        await firestore.salvarProgresso(video.url, maior);
      } catch (e) {}
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

    await carregarVideosLocais();
    await carregarProgresso();

    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Thumbnail criada 🎬")));
  }

  VideoModel? pegarUltimoVideoAssistido() {
    VideoModel? ultimoVideo;
    int maiorTempo = 0;

    for (var video in [...listaVideos, ...videosLocais]) {
      int tempo = progressoVideos[video.url] ?? 0;
      if (tempo > maiorTempo) {
        maiorTempo = tempo;
        ultimoVideo = video;
      }
    }
    if (maiorTempo == 0) return null;
    return ultimoVideo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Video Aulas 🎓"),
        actions: [
          // ⭐ BOTÃO PLAYLISTS ADICIONADO
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistsPage()),
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

          if (pegarUltimoVideoAssistido() != null) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Continuar assistindo 🎬",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            _buildContinuarAssistindo(pegarUltimoVideoAssistido()!),
          ],

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Todas as aulas 📚",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),

          ...videosLocais.map((v) =>
              _buildVideoCard(v, progressoVideos[v.url] ?? 0)),

          ...listaVideos.map((v) =>
              _buildVideoCard(v, progressoVideos[v.url] ?? 0)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video, int segundosAssistidos) {
    const int duracaoTotal = 180;
    double porcentagem = segundosAssistidos / duracaoTotal;
    if (porcentagem > 1) porcentagem = 1;
    bool concluido = porcentagem >= 0.95;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoPlayerPage(url: video.url)),
            );
            carregarProgresso();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: video.thumbnail.startsWith("/")
                    ? Image.file(File(video.thumbnail),
                    height: 180, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(video.thumbnail,
                    height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(video.titulo,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (concluido)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text("Concluído",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  if (video.isLocal)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deletarVideoLocal(video),
                    ),
                ],
              ),

              const SizedBox(height: 10),
              Text("Assistido: ${(porcentagem * 100).toStringAsFixed(0)}%"),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: porcentagem),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildContinuarAssistindo(VideoModel video) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoPlayerPage(url: video.url)),
          );
          carregarProgresso();
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
          ),
          child: Center(
            child: Text("Continuar: ${video.titulo}",
                style: const TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
