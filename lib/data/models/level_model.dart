import 'package:flutter/material.dart';

// 1. Modelo del Desafío (Hijo)
class Challenge {
  final String question;
  final String? codeSnippet;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  Challenge({
    required this.question,
    this.codeSnippet,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      question: map['question'] ?? '',
      codeSnippet: map['code_snippet'],
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correct_index'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

class LevelModel {
  final String id;
  final String title;
  final String subtitle;
  final int orderIndex; 
  final String iconName;
  final String colorHex;

  // Info de Intro
  final String description;
  final String analogy;

  // Datos del Juego
  final List<Challenge> challenges;

  LevelModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.orderIndex, 
    required this.iconName,
    required this.colorHex,
    required this.description,
    required this.analogy,
    required this.challenges,
  });

  
  factory LevelModel.fromMap(Map<String, dynamic> map, String id) {
    return LevelModel(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      orderIndex: map['order_index'] ?? 0,
      iconName: map['icon_name'] ?? 'code',
      colorHex: map['color_hex'] ?? '0xFF00FF00',
      description: map['description'] ?? 'Sin descripción.',
      analogy: map['analogy'] ?? 'Sin analogía.',
      challenges: List<Challenge>.from(
        (map['challenges'] as List? ?? []).map((x) => Challenge.fromMap(x)),
      ),
    );
  }

  // --- HELPERS PARA OBTENER EL COLOR Y EL ICONO DESDE LA BASE DE DATOS ---

  Color get color {
    try {
      return Color(int.parse(colorHex));
    } catch (_) {
      return const Color(0xFF00FF00);
    }
  }

  IconData get icon {
    switch (iconName) {
      case 'coffee':
        return Icons.coffee;
      case 'bug':
        return Icons.bug_report;
      case 'lock':
        return Icons.lock;
      case 'network':
        return Icons.wifi;
      case 'loop':
        return Icons.loop;
      case 'inventory_2': 
        return Icons.inventory_2;
      default:
        return Icons.code;
    }
  }
}
