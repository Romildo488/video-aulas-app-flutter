import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class VideoPlayerPage extends StatefulWidget {
  final String url;

  /// ⭐ NOVO — PLAYLIST
  final List<String>? playlistUrls;
  final int? playlistIndex;

  const VideoPlayerPage({
    super.key,
    required this.url,
    this.playlistUrls,
    this.playlistIndex,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  Timer? _timer;
  Timer? _hideControlsTimer;
  final firestore = FirestoreService();

  bool mostrarControles = true;
  bool isFullscreen = false;

  /// ⭐ CONTROLE PLAYLIST
  int indexAtual = 0;

  ////////////////////////////////////////////////////////////////
  String formatarTempo(Duration d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    final m = dois(d.inMinutes.remainder(60));
    final s = dois(d.inSeconds.remainder(60));
    return "$m:$s";
  }

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
  /// ⭐ AUTOPLAY PRÓXIMO VÍDEO
  void verificarFimDoVideo() {
    if (_controller.value.position >= _controller.value.duration &&
        widget.playlistUrls != null) {
      proximoVideo();
    }
  }

  Future<void> proximoVideo() async {
    if (widget.playlistUrls == null) return;
    if (indexAtual + 1 >= widget.playlistUrls!.length) return;

    indexAtual++;
    await _trocarVideo(widget.playlistUrls![indexAtual]);
  }

  ////////////////////////////////////////////////////////////////
  Future<void> salvarAntesDeSair() async {
    if (!_controller.value.isInitialized) return;
    final segundos = _controller.value.position.inSeconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.url, segundos);
    try { await firestore.salvarProgresso(widget.url, segundos); } catch (_) {}
  }

  ////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    indexAtual = widget.playlistIndex ?? 0;
    _initVideo(widget.url);
    WakelockPlus.enable();
  }

  ////////////////////////////////////////////////////////////////
  Future<void> _trocarVideo(String url) async {
    await salvarAntesDeSair();
    _controller.dispose();
    await _initVideo(url);
  }

  ////////////////////////////////////////////////////////////////
  Future<void> _initVideo(String url) async {
    if (url.startsWith("http")) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else if (url.startsWith("/")) {
      _controller = VideoPlayerController.file(File(url));
    } else {
      _controller = VideoPlayerController.asset(url);
    }

    await _controller.initialize();

    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt(url) ?? 0;
    _controller.seekTo(Duration(seconds: savedSeconds));

    _controller.play();

    /// ⭐ LISTENER AUTOPLAY
    _controller.addListener(verificarFimDoVideo);

    iniciarTimerControles();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final position = _controller.value.position.inSeconds;
      await prefs.setInt(url, position);
      try { await firestore.salvarProgresso(url, position); } catch (_) {}
    });

    setState(() {});
  }

  ////////////////////////////////////////////////////////////////
  @override
  void dispose() {
    sairFullscreen();
    salvarAntesDeSair();
    _timer?.cancel();
    _hideControlsTimer?.cancel();
    _controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void playPause() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
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

            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            if (mostrarControles)
              Center(
                child: IconButton(
                  iconSize: 70,
                  color: Colors.white,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  onPressed: playPause,
                ),
              ),

            if (mostrarControles)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Slider(
                      value: _controller.value.position.inSeconds.toDouble(),
                      max: _controller.value.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _controller.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatarTempo(_controller.value.position),
                              style: const TextStyle(color: Colors.white)),
                          Text(
                            "-${formatarTempo(_controller.value.duration - _controller.value.position)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            if (mostrarControles)
              Positioned(
                bottom: 50,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    alternarFullscreen();
                    iniciarTimerControles();
                  },
                ),
              ),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
