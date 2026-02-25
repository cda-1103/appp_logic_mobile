import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameViewModel extends ChangeNotifier {
  // 1. INYECCIÓN: Recibimos el repo, no lo creamos aquí
  final AuthRepository _authRepo;

  GameViewModel({required AuthRepository authRepo}) : _authRepo = authRepo;

  // --- VARIABLES DE ESTADO ---
  LevelModel? _currentLevel; // Guardamos el objeto entero (Info + Retos)
  List<Challenge> _challenges = [];

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _streak = 0; // NUEVO: Racha de aciertos seguidos

  // Configuración
  final int _maxLives = 2;
  int _currentLives = 2;

  // Estado de la UI
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;
  bool _isSaving = false; // Para mostrar loading al final

  // --- GETTERS ---
  LevelModel? get currentLevel => _currentLevel;

  Challenge? get currentChallenge =>
      _challenges.isNotEmpty && _currentQuestionIndex < _challenges.length
      ? _challenges[_currentQuestionIndex]
      : null;

  int get currentQuestionIndex =>
      _currentQuestionIndex; // Índice base 0 para lógica
  int get displayQuestionIndex =>
      _currentQuestionIndex + 1; // Para mostrar en UI (1/10)
  int get totalQuestions => _challenges.length;
  int get score => _score;
  int get streak => _streak;
  int get currentLives => _currentLives;
  int get maxLives => _maxLives;

  // Getters UI
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isChecked => _isChecked;
  bool get isCorrect => _isCorrect;
  bool get isSaving => _isSaving;

  // ------------------------------------------------------
  // 1. CARGAR NIVEL (Desde la Pantalla de Intro)
  // ------------------------------------------------------
  void loadLevel(LevelModel level) {
    _currentLevel = level;
    _challenges = level.challenges;

    // Reiniciamos todo a estado inicial
    _currentLives = _maxLives;
    _currentQuestionIndex = 0;
    _score = 0;
    _streak = 0;

    _resetQuestionState();

    notifyListeners();
  }

  // ------------------------------------------------------
  // 2. LÓGICA DE JUEGO
  // ------------------------------------------------------

  void selectOption(int index) {
    if (_isChecked) return; // Bloquear si ya respondió
    _selectedOptionIndex = index;
    notifyListeners();
  }

  void checkAnswer() {
    // Protección: Si no ha seleccionado nada o ya chequeó, no hacer nada
    if (_selectedOptionIndex == null || _isChecked) return;

    _isChecked = true;
    final correctIndex = currentChallenge!.correctOptionIndex;

    if (_selectedOptionIndex == correctIndex) {
      // --- ACIERTO ---
      _isCorrect = true;
      _streak++;
      _calculateScore(); // Sumar puntos con bonus
    } else {
      // --- ERROR ---
      _isCorrect = false;
      _streak = 0; // Se rompe la racha
      if (_currentLives > 0) {
        _currentLives--;
      }
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _challenges.length) {
      _currentQuestionIndex++;
      _resetQuestionState();
      notifyListeners();
    }
  }

  // Helper para limpiar la UI entre preguntas
  void _resetQuestionState() {
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;
  }

  void _calculateScore() {
    // Base: 100 XP por respuesta correcta
    int points = 100;
    // Bonus: +20 XP si tienes racha de 2 o más
    if (_streak >= 2) points += 20;
    _score += points;
  }

  // ------------------------------------------------------
  // 3. FINALIZAR Y GUARDAR
  // ------------------------------------------------------

  Future<bool> finishLevel() async {
    // Condición de victoria: Terminar con al menos 1 vida
    bool passed = _currentLives > 0;

    if (passed && _currentLevel != null) {
      _isSaving = true;
      notifyListeners();

      try {
        // Obtener el ID del usuario actual de Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        // Calcular estrellas
        int stars = 1;
        if (_currentLives == _maxLives)
          stars = 3;
        else if (_currentLives == _maxLives - 1)
          stars = 2;

        // Calcular respuestas correctas (asumiendo 100 puntos por respuesta base)
        // Ojo: Si usas bonus de racha, esto es un aproximado.
        // Si prefieres exactitud, podemos crear una variable _correctAnswersCount.
        int correctAnswers = _score ~/ 100;

        // LLAMADA CORREGIDA (Argumentos posicionales en orden)
        await _authRepo.updateLevelProgress(
          user.uid, // 1. userId (String)
          _currentLevel!.id, // 2. levelId (String)
          _score, // 3. score (int)
          stars, // 4. stars (int)
          correctAnswers, // 5. correctAnswers (int)
          _challenges.length, // 6. totalQuestions (int)
        );
      } catch (e) {
        print("Error guardando progreso: $e");
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }

    return passed;
  }
}
