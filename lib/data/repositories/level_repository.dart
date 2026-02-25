import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level_model.dart';

//todas las operaciones que se van a realizar en la base de datos con respecto a los niveles
class LevelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los niveles
  Future<List<LevelModel>> getLevels() async {
    try {
      final snapshot = await _firestore.collection('levels').get();

      return snapshot.docs.map((doc) {
        // AQUÍ ESTABA EL ERROR:
        // Ahora pasamos 2 argumentos: (Data, ID)
        return LevelModel.fromMap(doc.data(), doc.id);

        // PLAN B (Si no cambiaste el modelo y solo acepta 1 argumento):
        // final data = doc.data();
        // data['id'] = doc.id; // Inyectamos el ID en el mapa a la fuerza
        // return LevelModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error obteniendo niveles: $e");
      return []; // Retorna lista vacía si falla
    }
  }

  // Obtener un nivel específico por ID
  Future<LevelModel?> getLevelById(String levelId) async {
    try {
      final doc = await _firestore.collection('levels').doc(levelId).get();
      if (doc.exists) {
        // Igual aquí, pasamos data y id
        return LevelModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print("Error buscando nivel $levelId: $e");
      return null;
    }
  }
}
