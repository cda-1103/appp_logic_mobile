import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/level_model.dart'; 

class AiMentorService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  AiMentorService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
    );

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
      return response.text ?? "Mi procesador neuronal está descansando. ¡Sigue intentándolo!";
    } catch (e) {
      return "Hubo un problema de conexión. El Mentor no está disponible.";
    }
  }

  // --- FUNCIÓN 2: EL GENERADOR DE NIVELES COMPLETOS EN TIEMPO REAL ---
  Future<LevelModel?> generateAiLevel({
    required String topic,
    required String contextTheme,
    required String difficulty,
    required int numChallenges,
  }) async {
    try {
      print("🤖 [IA] Enviando prompt a Gemini... (Esperando 10-15 seg)");

      final prompt = '''
        Eres un profesor universitario experto en lógica de programación.
        Genera UN NIVEL EDUCATIVO COMPLETO para una App Móvil.
        - Tema de programación a enseñar: "$topic".
        - TEMÁTICA/UNIVERSO para los ejemplos: "$contextTheme".
        - Nivel de dificultad: $difficulty.
        - Cantidad de preguntas/retos a generar: $numChallenges.
        
        DEBES devolver un objeto JSON estricto con esta estructura exacta:
        {
          "title": "NOMBRE DEL TEMA CORTO EN MAYÚSCULAS",
          "subtitle": "Un subtítulo creativo basado en la temática",
          "description": "Una breve introducción pedagógica que explique la teoría básica de este tema, ambientada en la temática elegida.",
          "analogy": "Una analogía sencilla ambientada en la temática elegida para entender el concepto de programación.",
          "challenges": [
            {
              "question": "Pregunta de razonamiento o código acorde a la dificultad $difficulty. Usa la temática '$contextTheme' en el enunciado.",
              "code_snippet": "Fragmento de código corto (o vacío ''). Todo el código largo DEBE ir aquí.",
              "options": ["Opción A", "Opción B", "Opción C"], 
              "correct_index": 0, 
              "explanation": "Una explicación corta de por qué esa es la respuesta correcta."
            }
          ]
        }
        
        REGLAS VITALES PARA DISEÑO MÓVIL (¡CUMPLE ESTO ESTRICTAMENTE!):
        1. Las opciones dentro del arreglo "options" DEBEN SER MUY CORTAS (máximo 5-7 palabras por opción).
        2. ESTÁ PROHIBIDO poner párrafos largos explicativos o bloques de seudocódigo grandes dentro de las "options". 
        3. Si la pregunta requiere que el alumno lea código, pon ABSOLUTAMENTE TODO ese código dentro de "code_snippet".
        4. Las "options" solo deben contener el resultado final (Ejemplo de opciones válidas: "Dar error", "Devolver 0", "Bucle infinito", "Imprimir 'Hola'").
        5. "options" SIEMPRE debe tener 3 elementos.
        6. "correct_index" debe ser 0, 1 o 2.
      ''';

      final content = [Content.text(prompt)];
      final response = await _jsonModel.generateContent(content);
      
      print("🤖 [IA] Respuesta recibida. Procesando texto...");

      String rawText = response.text ?? '{}';
      
      final RegExp regex = RegExp(r'\{[\s\S]*\}');
      final match = regex.firstMatch(rawText);
      
      String cleanJson = '{}';
      if (match != null) {
        cleanJson = match.group(0)!;
      } else {
        print("❌ [IA ERROR] No se encontró estructura JSON en la respuesta.");
        return null;
      }

      cleanJson = cleanJson.replaceAll('```json', '').replaceAll('```', '').trim();
      
      print("🤖 [IA] Decodificando JSON...");
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      List<Challenge> generatedChallenges = [];
      if (data['challenges'] != null) {
        for (var c in data['challenges']) {
          generatedChallenges.add(Challenge.fromMap(c));
        }
      }

      print("✅ [IA ÉXITO] Nivel generado y empaquetado correctamente.");

      return LevelModel(
        id: "ai_lvl_${DateTime.now().millisecondsSinceEpoch}",
        title: data['title'] ?? "RETO IA: $topic",
        subtitle: data['subtitle'] ?? "Universo: $contextTheme",
        orderIndex: 999,
        iconName: "auto_awesome",
        colorHex: "0xFF9C27B0",
        description: data['description'] ?? "Concepto generado por Inteligencia Artificial.",
        analogy: data['analogy'] ?? "Mente humana vs Máquina.",
        challenges: generatedChallenges,
      );

    } catch (e) {
      print("❌ [IA EXCEPCIÓN FATAL] Error generando Nivel: $e");
      return null;
    }
  }
}