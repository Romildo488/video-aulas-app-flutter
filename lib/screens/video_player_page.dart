import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  Timer? _timer;
  final firestore = FirestoreService();

  bool isFullscreen = false;

  // ⭐ CONTROLES AUTO HIDE
  bool mostrarControles = true;
  Timer? _hideControlsTimer;

  ////////////////////////////////////////////////////////////////
  void iniciarTimerControles() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => mostrarControles = false);
    });
  }

  void alternarControles() {
    setState(() => mostrarControles = !mostrarControles);
    if (mostrarControles) iniciarTimerControles();
  }

  ////////////////////////////////////////////////////////////////
  void entrarFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    isFullscreen = true;
  }

  void sairFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isFullscreen = false;
  }

  void alternarFullscreen() {
    setState(() {
      isFullscreen ? sairFullscreen() : entrarFullscreen();
    });
  }

  ////////////////////////////////////////////////////////////////
  Future<void> salvarAntesDeSair() async {
    if (!_controller.value.isInitialized) return;
    final segundos = _controller.value.position.inSeconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.url, segundos);
    try { await firestore.salvarProgresso(widget.url, segundos); } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  ////////////////////////////////////////////////////////////////
  Future<void> _initVideo() async {

    if (widget.url.startsWith("http")) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    } else if (widget.url.startsWith("/")) {
      _controller = VideoPlayerController.file(File(widget.url));
    } else {
      _controller = VideoPlayerController.asset(widget.url);
    }

    await _controller.initialize();

    // ⭐⭐ NOVO — IMPEDIR TELA APAGAR
    await WakelockPlus.enable();

    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt(widget.url) ?? 0;
    _controller.seekTo(Duration(seconds: savedSeconds));
    setState(() {});

    iniciarTimerControles();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final position = _controller.value.position.inSeconds;
      await prefs.setInt(widget.url, position);
      try { await firestore.salvarProgresso(widget.url, position); } catch (_) {}
    });
  }

  ////////////////////////////////////////////////////////////////
  @override
  void dispose() {
    sairFullscreen();
    salvarAntesDeSair();
    _timer?.cancel();
    _hideControlsTimer?.cancel();

    // ⭐⭐ NOVO — LIBERA TELA PARA APAGAR NOVAMENTE
    WakelockPlus.disable();

    _controller.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////////////
  void playPause() async {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
    iniciarTimerControles();
  }

  ////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isFullscreen ? null : AppBar(title: const Text("Assistir Aula")),
      body: _controller.value.isInitialized
          ? GestureDetector(
        onTap: alternarControles,
        child: Stack(
          children: [

            /// 🎬 VIDEO PROPORCIONAL
            Center(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),

            /// ▶️ PLAY / PAUSE
            if (mostrarControles)
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton(
                  heroTag: "play",
                  onPressed: playPause,
                  child: Icon(_controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
              ),

            /// 📺 FULLSCREEN
            if (mostrarControles)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  heroTag: "fullscreen",
                  onPressed: () {
                    alternarFullscreen();
                    iniciarTimerControles();
                  },
                  child: Icon(isFullscreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen),
                ),
              ),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
