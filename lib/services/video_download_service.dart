import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoDownloadService {
  final Dio dio = Dio();

  Future<String?> baixarVideo(String url, String nome) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pasta = Directory("${dir.path}/videos");

      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final caminhoArquivo = "${pasta.path}/$nome.mp4";

      await dio.download(
        url,
        caminhoArquivo,
        onReceiveProgress: (recebido, total) {
          if (total != -1) {
            print("Download: ${(recebido / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      return caminhoArquivo;
    } catch (e) {
      print("Erro download: $e");
      return null;
    }
  }
}
