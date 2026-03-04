import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/level_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';
import '../../core/services/ai_mentor_service.dart';
import 'level_intro_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<LevelModel>> _levelsFuture;
  
  // --- VARIABLES PARA LA IA ---
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _themeController = TextEditingController(); 
  final AiMentorService _aiService = AiMentorService();

  @override
  void initState() {
    super.initState();
    final levelRepo = Provider.of<LevelRepository>(context, listen: false);
    _levelsFuture = levelRepo.getLevels();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _themeController.dispose(); 
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // ---> MÉTODOS DE INTELIGENCIA ARTIFICIAL <---
  // ----------------------------------------------------------------------

  // NOTA ARQUITECTÓNICA: Quitamos el parámetro 'context' para no hacer "Shadowing" 
  // y usar el 'context' estable de la clase State.
  void _showAiGeneratorDialog() {
    String localDifficulty = 'Medio';
    int localChallengesCount = 1;

    showDialog(
      context: context, // Usamos el context global de la pantalla
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext statefulContext, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF9C27B0)), // Morado IA
              ),
              title: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
                  SizedBox(width: 8),
                  Text(
                    "CREA TU NIVEL",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "El Mentor IA creará teoría y preguntas a tu medida.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    
                    // 1. INPUT DEL TEMA DE PROGRAMACIÓN
                    TextField(
                      controller: _topicController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      cursorColor: const Color(0xFF9C27B0),
                      decoration: InputDecoration(
                        labelText: "Tema (Ej. Variables, Bucles...)",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF9C27B0))),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1.5 INPUT DEL CONTEXTO/TEMÁTICA 
                    TextField(
                      controller: _themeController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      cursorColor: const Color(0xFF00FF00), 
                      decoration: InputDecoration(
                        labelText: "Temática (Ej. Premier League, Tenis...)",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00FF00))),
                        prefixIcon: const Icon(Icons.theater_comedy, color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. DROPDOWN DE DIFICULTAD
                    DropdownButtonFormField<String>(
                      value: localDifficulty,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      decoration: InputDecoration(
                        labelText: "Dificultad",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: ['Fácil', 'Medio', 'Difícil'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() => localDifficulty = newValue!);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. DROPDOWN DE CANTIDAD DE RETOS
                    DropdownButtonFormField<int>(
                      value: localChallengesCount,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      decoration: InputDecoration(
                        labelText: "Cantidad de Desafíos",
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: [1, 2, 3].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value, 
                          child: Text("$value ${value == 1 ? 'Desafío' : 'Desafíos'}"),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() => localChallengesCount = newValue!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final topic = _topicController.text.trim();
                    final theme = _themeController.text.trim().isEmpty 
                        ? "Tecnología" 
                        : _themeController.text.trim();

                    if (topic.isNotEmpty) {
                      Navigator.pop(dialogContext); // Cerramos el formulario
                      // Llamamos a la función sin pasarle ningún context corrupto
                      _generateAndPlayLevel(topic, theme, localDifficulty, localChallengesCount); 
                    }
                  },
                  child: const Text("GENERAR NIVEL", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---> FUNCIÓN BLINDADA CONTRA SPINNER INFINITO <---
  Future<void> _generateAndPlayLevel(String topic, String theme, String difficulty, int challengesCount) async {
    // 1. Mostrar diálogo de carga seguro
    showDialog(
      context: context, // Usamos el context global
      barrierDismissible: false,
      builder: (BuildContext loadingDialogContext) => const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF9C27B0)),
              SizedBox(height: 16),
              Text(
                "El Mentor IA está redactando la teoría...\n(Puede tardar hasta 15 segundos)",
                style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 2. Pedirle el nivel completo a la IA
      final generatedLevel = await _aiService.generateAiLevel(
        topic: topic,
        contextTheme: theme,
        difficulty: difficulty,
        numChallenges: challengesCount,
      );

      // 3. Quitar el diálogo de carga
      if (!mounted) return; // 'mounted' es global al State
      Navigator.of(context, rootNavigator: true).pop();

      // 4. Evaluar resultado y navegar
      if (generatedLevel != null && mounted) {
        _topicController.clear(); 
        _themeController.clear();
        
        final gameVM = Provider.of<GameViewModel>(context, listen: false);
        gameVM.loadLevel(generatedLevel);
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LevelIntroScreen(level: generatedLevel)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El Mentor falló al generar el nivel. Revisa la consola.", style: TextStyle(fontFamily: 'Courier')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 5. En caso de error, quitamos el loading y avisamos
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error interno: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // ---> CONSTRUCCIÓN DE LA PANTALLA PRINCIPAL <---
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;
    final int solvedLevels = user?.solvedLevels ?? 0;

    final neonGreen = const Color(0xFF00FF00);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "SELECCIONAR NIVEL",
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildUserHeader(user, neonGreen),

          Expanded(
            child: FutureBuilder<List<LevelModel>>(
              future: _levelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: neonGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final levels = snapshot.data ?? [];
                levels.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

                if (levels.isEmpty) {
                  return const Center(child: Text("NO DATA FOUND", style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final bool isLocked = index > solvedLevels;
                    return _buildLevelCard(context, level, isLocked);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          "CREAR NIVEL CON IA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier', letterSpacing: 1),
        ),
        onPressed: () => _showAiGeneratorDialog(), // Ya no le pasamos el context
      ),
    );
  }

  // --- WIDGET ENCABEZADO DE USUARIO ---
  Widget _buildUserHeader(dynamic user, Color neonGreen) {
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1F2937),
            child: Icon(Icons.person, color: neonGreen, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.rankTitle ?? "Aprendiz Junior",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Courier'),
                ),
                Text(
                  user.username.toUpperCase(),
                  style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Courier'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: neonGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: neonGreen, size: 16), 
                const SizedBox(width: 4),
                Text(
                  "${user.totalScore} XP",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TARJETA DE NIVEL ---
  Widget _buildLevelCard(BuildContext context, LevelModel level, bool isLocked) {
    final baseColor = isLocked ? Colors.grey : level.color;
    final icon = isLocked ? Icons.lock : level.icon;
    final opacity = isLocked ? 0.5 : 1.0;

    return GestureDetector(
      onTap: isLocked
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nivel bloqueado. Completa el anterior primero.")))
          : () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelIntroScreen(level: level))),
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? Colors.grey.withOpacity(0.3) : baseColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(shape: BoxShape.circle, color: baseColor.withOpacity(0.1)),
                child: Icon(icon, color: baseColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLocked ? "NIVEL BLOQUEADO" : level.title.toUpperCase(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: isLocked ? null : 'Courier'),
                    ),
                    const SizedBox(height: 4),
                    Text(level.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (!isLocked) const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}