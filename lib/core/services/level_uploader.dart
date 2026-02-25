import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LevelUploader {
  static Future<void> uploadLevels() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/levels/levels.json',
      );
      final Map<String, dynamic> data = json.decode(response);

      final List<dynamic> levelsList = data['levels'];

      print("Iniciando subida de niveles.....");

      final batch = FirebaseFirestore.instance.batch();

      for (var level in levelsList) {
        final docRef = FirebaseFirestore.instance
            .collection('levels')
            .doc(level['id']);
        batch.set(docRef, level);
        print("nivel ${level['id']} subido");
      }
      await batch.commit();

      print(
        'niveles subidos satisfactoriamente se han subido: ${levelsList.length} niveles',
      );
    } catch (e) {
      print('Error al subir niveles: $e');
    }
  }
}
