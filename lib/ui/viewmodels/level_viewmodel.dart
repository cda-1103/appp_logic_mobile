import 'package:appp_logic_mobile/data/models/level_model.dart';
import 'package:appp_logic_mobile/data/repositories/level_repository.dart';
import 'package:flutter/material.dart';

class LevelViewModel extends ChangeNotifier {
  final LevelRepository _levelRepo = LevelRepository();

  List<LevelModel> _levels = [];
  bool _isLoading = false;

  List<LevelModel> get levels => _levels;
  bool get isLoading => _isLoading;

  Future<void> loadLevels() async {
    _isLoading = true;
    notifyListeners();

    try {
      _levels = await _levelRepo.getLevels();
    } catch (e) {
      print("Error al cargar niveles: $e");
    }
    _isLoading = false;
    notifyListeners();
  }
}
