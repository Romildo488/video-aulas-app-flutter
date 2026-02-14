import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class LocalVideoService {

  Future<String?> escolherVideo() async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null) return null;

    final caminhoOriginal = result.files.single.path!;
    final arquivoOriginal = File(caminhoOriginal);

    // 📁 pasta permanente do app
    final dir = await getApplicationDocumentsDirectory();

    // cria nome único
    final nomeArquivo = basename(caminhoOriginal);
    final novoCaminho = "${dir.path}/$nomeArquivo";

    // 📌 COPIA O VIDEO PARA PASTA PERMANENTE
    final novoArquivo = await arquivoOriginal.copy(novoCaminho);

    print("VIDEO COPIADO PARA:");
    print(novoArquivo.path);

    return novoArquivo.path;
  }
}
