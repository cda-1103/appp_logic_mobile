class UserModel {
  final String uid;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final int totalScore;
  final int lives;
  final int streak;
  final int solvedLevels;
  final double accuracy;

  final Map<String, dynamic> levelProgress;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.totalScore = 0,
    this.lives = 2,
    this.streak = 0,
    this.solvedLevels = 0,
    this.accuracy = 0,
    this.levelProgress = const {},
  });

  // --- LÓGICA DE PROGRESO DE NIVEL (DINÁMICA) ---

  int get currentLevel {
    return (totalScore / 500).floor() + 1;
  }

  // 2. Calcula la meta del siguiente nivel (Ej: Nivel 2 * 500 = 1000)
  int get nextLevelXp {
    return currentLevel * 500;
  }

  // 3. Cuánto falta para subir de nivel
  int get xpToNextLevel {
    return nextLevelXp - totalScore;
  }

  // 4. Porcentaje (0.0 a 1.0)
  double get levelProgressPercentage {
    if (totalScore == 0) return 0.0;
    int xpInCurrentLevel = totalScore % 500;
    return xpInCurrentLevel / 500.0;
  }

  // --- LÓGICA DE RANGOS ---
  String get rankTitle {
    if (currentLevel < 3) return 'Aprendiz Junior';
    if (currentLevel < 5) return 'Aprendiz del Algoritmo';
    if (currentLevel < 10) return 'Ingeniero del Algoritmo';
    if (currentLevel < 15) return 'Arquitecto de Sistemas';
    return 'Maestro del Código';
  }

  // 1. De Firebase (Map) a Objeto Dart
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final stats = map['stats'] as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: documentId,
      email: map['email']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString()) ?? DateTime.now()
          : DateTime.now(),

      totalScore: (stats['total_score'] ?? 0).toInt(),

      lives: (stats['lives'] ?? 5).toInt(),
      streak: (stats['current_streak'] ?? 0).toInt(),
      solvedLevels: (stats['solved_levels'] ?? 0).toInt(),
      accuracy: (stats['accuracy'] ?? 0).toDouble(),

      levelProgress: map['level_progress'] ?? {},
    );
  }

  // 2. De Objeto Dart a Firebase (Map)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'stats': {
        'total_score': totalScore,
        'current_level':
            currentLevel, // Guardamos el valor calculado para referencias futuras
        'lives': lives,
        'current_streak': streak,
        'solved_levels': solvedLevels,
        'accuracy': accuracy,
      },
      'level_progress': levelProgress,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    int? totalScore,
    int? lives,
    int? streak,
    int? solvedLevels,
    double? accuracy,
    Map<String, dynamic>? levelProgress,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth,
      totalScore: totalScore ?? this.totalScore,
      lives: lives ?? this.lives,
      streak: streak ?? this.streak,
      solvedLevels: solvedLevels ?? this.solvedLevels,
      accuracy: accuracy ?? this.accuracy,
      levelProgress: levelProgress ?? this.levelProgress,
    );
  }
}
