class VideoModel {
  final String titulo;
  final String url;
  final String thumbnail;
  final bool isLocal;
  final String categoria;

  VideoModel({
    required this.titulo,
    required this.url,
    required this.thumbnail,
    this.isLocal = false,
    this.categoria = "Aulas",
  });

  /////////////////////////////////////////////////////////////
  // ⭐ CONVERTER PARA JSON (SALVAR NO CELULAR)
  /////////////////////////////////////////////////////////////
  Map<String, dynamic> toJson() {
    return {
      "titulo": titulo,
      "url": url,
      "thumbnail": thumbnail,
      "isLocal": isLocal,
      "categoria": categoria,
    };
  }

  /////////////////////////////////////////////////////////////
  // ⭐ CRIAR OBJETO A PARTIR DO JSON (LER DO CELULAR)
  /////////////////////////////////////////////////////////////
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      titulo: json["titulo"],
      url: json["url"],
      thumbnail: json["thumbnail"],
      isLocal: json["isLocal"] ?? false,
      categoria: json["categoria"] ?? "Aulas",
    );
  }
}
