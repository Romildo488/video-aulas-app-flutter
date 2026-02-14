import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class LocalVideosStorage {
  final String key = "videos_locais";

  //////////////////////////////////////////////////////////////
  // SALVAR LISTA DE VIDEOS
  //////////////////////////////////////////////////////////////
  Future<void> salvarVideos(List<VideoModel> videos) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> listaJson =
    videos.map((video) => jsonEncode(video.toJson())).toList();

    await prefs.setStringList(key, listaJson);
  }

  //////////////////////////////////////////////////////////////
  // CARREGAR LISTA DE VIDEOS
  //////////////////////////////////////////////////////////////
  Future<List<VideoModel>> carregarVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(key);

    if (listaJson == null) return [];

    return listaJson
        .map((item) => VideoModel.fromJson(jsonDecode(item)))
        .toList();
  }
}
