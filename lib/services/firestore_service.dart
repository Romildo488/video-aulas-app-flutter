import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // pega o id do usuário logado
  String get uid => _auth.currentUser!.uid;

  // SALVAR progresso do vídeo
  Future<void> salvarProgresso(String videoUrl, int segundos) async {
    final safeId = Uri.encodeComponent(videoUrl);

    await _db
        .collection("users")
        .doc(uid)
        .collection("progress")
        .doc(safeId)
        .set({
      "url": videoUrl,   // guardamos a URL original
      "segundos": segundos,
    });
  }


  // CARREGAR progresso do usuário
  Future<Map<String, int>> carregarProgresso() async {
    final snapshot = await _db
        .collection("users")
        .doc(uid)
        .collection("progress")
        .get();

    Map<String, int> progresso = {};

    for (var doc in snapshot.docs) {
      progresso[doc["url"]] = doc["segundos"];
    }

    return progresso;
  }

}
