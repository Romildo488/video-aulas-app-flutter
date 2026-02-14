import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ThumbnailService {

  Future<String?> gerarThumbnail(String videoPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 90,
      );

      print("THUMB CRIADA: $thumbPath");

      return thumbPath;
    } catch (e) {
      print("ERRO AO GERAR THUMB ❌");
      print(e);
      return null;
    }
  }
}
