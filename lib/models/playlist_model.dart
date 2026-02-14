import '../models/video_model.dart';

class PlaylistModel {
  String nome;
  List<VideoModel> videos;

  PlaylistModel({
    required this.nome,
    required this.videos,
  });

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "videos": videos.map((v) => v.toJson()).toList(),
  };

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      nome: json["nome"],
      videos: (json["videos"] as List)
          .map((v) => VideoModel.fromJson(v))
          .toList(),
    );
  }
}
