import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';

class PlaylistStorage {
  static const key = "playlists";

  Future<List<PlaylistModel>> carregarPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(key);

    if (listaJson == null) return [];

    return listaJson
        .map((item) => PlaylistModel.fromJson(jsonDecode(item)))
        .toList();
  }

  Future<void> salvarPlaylists(List<PlaylistModel> playlists) async {
    final prefs = await SharedPreferences.getInstance();

    final listaJson =
    playlists.map((p) => jsonEncode(p.toJson())).toList();

    await prefs.setStringList(key, listaJson);
  }
}
