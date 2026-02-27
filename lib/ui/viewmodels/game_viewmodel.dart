import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/ai_mentor_service.dart';

class GameViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  
  // Instanciamos el servicio (podríamos inyectarlo, pero para la tesis así es rápido y válido)
  final AiMentorService _aiMentor = AiMentorService();

  GameViewModel({required AuthRepository authRepo}) : _authRepo = authRepo;

  // --- VARIABLES DE ESTADO ---
  LevelModel? _currentLevel;
  List<Challenge> _challenges = [];

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _streak = 0; 

  final int _maxLives = 2;
  int _currentLives = 2;

  // Estado de la UI
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;
  bool _isSaving = false; 

  List<String> _currentShuffledOptions = [];
  String _userImputText = "";
  final TextEditingController textController = TextEditingController();

  // ---> NUEVOS ESTADOS PARA LA IA <---
  bool _isLoadingHint = false;
  String? _currentHint;

  // --- GETTERS ---
  LevelModel? get currentLevel => _currentLevel;
  Challenge? get currentChallenge =>
      _challenges.isNotEmpty && _currentQuestionIndex < _challenges.length
      ? _challenges[_currentQuestionIndex]
      : null;

  int get currentQuestionIndex => _currentQuestionIndex; 
  int get displayQuestionIndex => _currentQuestionIndex + 1; 
  int get totalQuestions => _challenges.length;
  int get score => _score;
  int get streak => _streak;
  int get currentLives => _currentLives;
  int get maxLives => _maxLives;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isChecked => _isChecked;
  bool get isCorrect => _isCorrect;
  bool get isSaving => _isSaving;
  List<String> get currentShuffledOptions => _currentShuffledOptions;
  String get userInputText => _userImputText;
  
  // Getters IA
  bool get isLoadingHint => _isLoadingHint;
  String? get currentHint => _currentHint;

  // ------------------------------------------------------
  // 1. CARGAR NIVEL 
  // ------------------------------------------------------
  void loadLevel(LevelModel level) {
    _currentLevel = level;
    _challenges = level.challenges;
    _currentLives = _maxLives;
    _currentQuestionIndex = 0;
    _score = 0;
    _streak = 0;
    _prepareCurrentChallenge();
    _resetQuestionState();
    notifyListeners();
  }

  // ------------------------------------------------------
  // 2. LÓGICA DE JUEGO
  // ------------------------------------------------------
  void _prepareCurrentChallenge(){
    if (currentChallenge != null){
      if (!currentChallenge!.isFillInTheBlank){
        _currentShuffledOptions = List <String>.from(currentChallenge!.options);
        _currentShuffledOptions.shuffle();
      } else {
        _currentShuffledOptions = [];
      }
    }
  }

  void loadAiGeneratedLevel(Challenge aiChallenge) {
    // Creamos un "Nivel Fantasma" solo para este reto
    _currentLevel = LevelModel(
      id: "ai_generated_challenge",
      title: "RETO IA",
      subtitle: "Supervivencia",
      orderIndex: 999,
      iconName: "auto_awesome",
      colorHex: "0xFF9C27B0", // Morado
      description: "Un reto único forjado por el Mentor IA.",
      analogy: "Mente contra Máquina.",
      challenges: [aiChallenge], // Solo tiene un reto
    );
    
    _challenges = _currentLevel!.challenges;

    // A diferencia de un nivel normal, aquí no perdonamos: 1 sola vida
    _currentLives = 1; 
    _currentQuestionIndex = 0;
    _score = 0;
    _streak = 0;

    _prepareCurrentChallenge();
    _resetQuestionState();

    notifyListeners();
  }

  void selectOption(int index) {
    if (_isChecked) return; 
    _selectedOptionIndex = index;
    notifyListeners();
  }

  void updateUserInput (String text){
    if (_isChecked) return;
    _userImputText = text;
    notifyListeners();
  }

  void checkAnswer() {
    if (_isChecked || currentChallenge == null) return ;

    final challenge = currentChallenge!;

    if (challenge.isFillInTheBlank){
      if (_userImputText.trim().isEmpty) return;
      _isChecked = true;
      String expected = challenge.expectedTextAnswer ?? "";
      _validateTextAnswer(_userImputText, expected);
    } else {
      if (_selectedOptionIndex == null) return;
      _isChecked = true;
      final String correctText = challenge.options[challenge.correctOptionIndex];
      final String selectedText = _currentShuffledOptions[_selectedOptionIndex!];

      if (selectedText == correctText){
        _handleCorrectAnswer();
      } else {
        _handleIncorrectAnswer();
      }
    }
    notifyListeners();
  }

  void _validateTextAnswer(String userInput, String expectedCode){
      String normalizedInput = userInput.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll('"', "'");
      String normalizedExpected = expectedCode.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll('"', "'");

      if (normalizedInput.endsWith(';')) normalizedInput = normalizedInput.substring(0, normalizedInput.length - 1);
      if (normalizedExpected.endsWith(';')) normalizedExpected = normalizedExpected.substring(0, normalizedExpected.length - 1);

      if (normalizedExpected == normalizedInput) {
        _handleCorrectAnswer();
      } else {
        _handleIncorrectAnswer();
      }
  }

  void _handleCorrectAnswer(){
    _isCorrect = true;
    _streak ++;
    _calculateScore();
  }

  void _handleIncorrectAnswer(){
    _isCorrect = false;
    _streak = 0;
    if (currentLives > 0) _currentLives --;
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _challenges.length - 1) {
      _currentQuestionIndex++;
      _prepareCurrentChallenge();
      _resetQuestionState();
      notifyListeners();
    }
  }

  void _resetQuestionState() {
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;
    _userImputText = "";
    _currentHint = null; // Reiniciamos la pista
    textController.clear(); 
  }

  void _calculateScore() {
    int points = 100;
    if (_streak >= 2) points += 20;
    _score += points;
  }

  // ---> NUEVO: PEDIR PISTA A LA IA <---
  Future<void> askForHint() async {
    if (currentChallenge == null || _isLoadingHint) return;

    _isLoadingHint = true;
    notifyListeners();

    String? wrongAnswer;
    if (currentChallenge!.isFillInTheBlank) {
      wrongAnswer = _userImputText;
    } else if (_selectedOptionIndex != null) {
      wrongAnswer = _currentShuffledOptions[_selectedOptionIndex!];
    }

    _currentHint = await _aiMentor.getHint(
      question: currentChallenge!.question,
      explanation: currentChallenge!.explanation,
      wrongAnswer: wrongAnswer,
    );

    _isLoadingHint = false;
    notifyListeners();
  }

  // ------------------------------------------------------
  // 3. FINALIZAR Y GUARDAR
  // ------------------------------------------------------
  Future<bool> finishLevel() async {
    bool passed = _currentLives > 0;
    if (passed && _currentLevel != null) {
      _isSaving = true;
      notifyListeners();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        int stars = 1;
        if (_currentLives == _maxLives) stars = 3;
        else if (_currentLives == _maxLives - 1) stars = 2;

        int correctAnswers = _score ~/ 100;

        await _authRepo.updateLevelProgress(
          user.uid, 
          _currentLevel!.id, 
          _score, 
          stars, 
          correctAnswers, 
          _challenges.length, 
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
  
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}