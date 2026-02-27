import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/level_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart'; // Añadido para poder jugar el reto IA
import '../../core/services/ai_mentor_service.dart'; // Añadido para llamar a Gemini
import 'level_intro_screen.dart';
import 'game_screen.dart'; // Añadido para navegar al juego directamente

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<LevelModel>> _levelsFuture;
  
  // --- VARIABLES PARA LA IA ---
  final TextEditingController _topicController = TextEditingController();
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
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // ---> MÉTODOS DE INTELIGENCIA ARTIFICIAL <---
  // ----------------------------------------------------------------------

  void _showAiGeneratorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                "FORJA TU RETO",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Escribe el tema de programación que quieres practicar y el Mentor IA creará un desafío único para ti.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                cursorColor: const Color(0xFF9C27B0),
                decoration: InputDecoration(
                  hintText: "Ej. Bucles For, Variables...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
              ),
            ],
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
                if (topic.isNotEmpty) {
                  Navigator.pop(dialogContext); 
                  _generateAndPlayLevel(context, topic); 
                }
              },
              child: const Text("GENERAR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndPlayLevel(BuildContext context, String topic) async {
    // 1. Mostrar diálogo de carga "Invocando al Mentor..."
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF9C27B0)),
              SizedBox(height: 16),
              Text(
                "El Mentor está forjando el reto...",
                style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
              ),
            ],
          ),
        ),
      ),
    );

    // 2. Pedirle el reto a la IA
    final reto = await _aiService.generateRandomChallenge(topic);

    // 3. Quitar el diálogo de carga
    if (!context.mounted) return;
    Navigator.pop(context);

    // 4. Evaluar resultado y navegar
    if (reto != null) {
      _topicController.clear(); // Limpiamos para el futuro
      
      // Cargamos el reto en el ViewModel general
      final gameVM = Provider.of<GameViewModel>(context, listen: false);
      gameVM.loadAiGeneratedLevel(reto);
      
      // Viajamos directo al juego
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    } else {
      // Mostrar error de red
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El Mentor no pudo forjar el reto. Intenta de nuevo.", style: TextStyle(fontFamily: 'Courier')),
          backgroundColor: Colors.red,
        ),
      );
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

    // Colores del tema
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
          // 1. EL ENCABEZADO DE USUARIO
          _buildUserHeader(user, neonGreen),

          // 2. LA LISTA DE NIVELES (Dentro de Expanded para ocupar el resto)
          Expanded(
            child: FutureBuilder<List<LevelModel>>(
              future: _levelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: neonGreen),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "ERROR: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final levels = snapshot.data ?? [];
                levels.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

                if (levels.isEmpty) {
                  return const Center(
                    child: Text(
                      "NO DATA FOUND",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
      // --- NUEVO: BOTÓN FLOTANTE MÁGICO DE IA ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF9C27B0), // Morado IA
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          "RETO IA",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontFamily: 'Courier',
            letterSpacing: 1.5,
          ),
        ),
        onPressed: () => _showAiGeneratorDialog(context),
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
          // A. Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1F2937),
            child: Icon(Icons.person, color: neonGreen, size: 28),
          ),
          const SizedBox(width: 12),

          // B. Nombre y Rango
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.rankTitle ?? "Aprendiz Junior",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
                Text(
                  user.username.toUpperCase(),
                  style: TextStyle(
                    color: neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),

          // C. Píldora de XP
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TARJETA DE NIVEL ---
  Widget _buildLevelCard(
    BuildContext context,
    LevelModel level,
    bool isLocked,
  ) {
    final baseColor = isLocked ? Colors.grey : level.color;
    final icon = isLocked ? Icons.lock : level.icon;
    final opacity = isLocked ? 0.5 : 1.0;

    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Nivel bloqueado. Completa el anterior primero.",
                  ),
                ),
              );
            }
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LevelIntroScreen(level: level),
                ),
              );
            },
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.withOpacity(0.3)
                  : baseColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withOpacity(0.1),
                ),
                child: Icon(icon, color: baseColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLocked ? "NIVEL BLOQUEADO" : level.title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: isLocked ? null : 'Courier',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}