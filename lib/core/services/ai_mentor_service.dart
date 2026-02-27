import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
// IMPORTANTE: Asegúrate de que la ruta a tu modelo sea correcta
import '../../data/models/level_model.dart'; 

class AiMentorService {
  // ATENCIÓN: Asegúrate de poner tu API Key real aquí.
  static const String _apiKey = 'AIzaSyCB4TEyO4jwvL27BpWqe8NfLjJL5SLhdJA'; 
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  AiMentorService() {
    // 1. Modelo normal para texto (Pistas del Mentor)
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
    );

    // 2. Modelo estricto configurado para devolver SIEMPRE formato JSON
    _jsonModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  // --- FUNCIÓN 1: EL MENTOR (Pistas) ---
  Future<String> getHint({
    required String question,
    required String explanation,
    String? wrongAnswer,
  }) async {
    try {
      final prompt = '''
        Actúa como un profesor de programación amable, empático y experto.
        Tu estudiante acaba de equivocarse en esta pregunta de lógica:
        Pregunta: "$question"
        La explicación de la respuesta correcta es: "$explanation"
        ${wrongAnswer != null ? 'El estudiante respondió erróneamente: "$wrongAnswer"' : ''}
        
        Tu tarea: Dale una PISTA CORTA (máximo 3 líneas) para que entienda su error y descubra la respuesta por sí mismo.
        REGLA DE ORO: ¡NO le des la respuesta directa! Solo guíalo con una analogía o pista.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? "Mi procesador neuronal está descansando. ¡Sigue intentándolo, tú puedes!";
    } catch (e) {
      print("Error detallado de Gemini AI: $e");
      return "Hubo un problema de conexión. El Mentor no está disponible.";
    }
  }

  // --- FUNCIÓN 2: EL GENERADOR DE RETOS EN TIEMPO REAL ---
  Future<Challenge?> generateRandomChallenge(String topic) async {
    try {
      final prompt = '''
        Eres un profesor universitario experto en lógica de programación y algoritmia básica.
        Genera UN (1) reto (Challenge) educativo, original y engañoso sobre el tema: "$topic".
        
        DEBES devolver un objeto JSON estricto con la siguiente estructura exacta:
        {
          "question": "Una pregunta de razonamiento lógico o código",
          "code_snippet": "Fragmento de código corto en Dart o seudocódigo (puede estar vacío '')",
          "options": ["Opción A", "Opción B", "Opción C"], 
          "correct_index": 0, 
          "explanation": "Una explicación pedagógica corta de por qué esa es la respuesta correcta."
        }
        
        Reglas vitales para el JSON:
        - Para la propiedad "options": Proporciona SIEMPRE un arreglo con 3 opciones (Múltiple selección).
        - Para "correct_index": Debe ser el número 0, 1 o 2, indicando cuál opción del arreglo es la correcta.
        - Para "expected_text": DEBE omitirse o ser null.
      ''';

      final content = [Content.text(prompt)];
      final response = await _jsonModel.generateContent(content);
      
      final String jsonString = response.text ?? '{}';
      print("JSON devuelto por Gemini: $jsonString"); 

      // Convertimos el JSON de Gemini a un Mapa de Dart
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Convertimos el Mapa en tu clase Challenge
      return Challenge.fromMap(data);

    } catch (e) {
      print("Error generando reto con IA: $e");
      return null;
    }
  }
}