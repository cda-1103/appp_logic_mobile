import 'package:appp_logic_mobile/ui/viewmodels/game_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/level_model.dart';
import 'game_screen.dart';

class LevelIntroScreen extends StatelessWidget {
  final LevelModel level;

  const LevelIntroScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    // --- COLORES & ESTILOS DEL TEMA ---
    final darkBg = const Color(0xFF0D1117);
    final cardColor = const Color(0xFF161B22);
    // Usamos el color del nivel, o verde por defecto si algo falla
    final accentColor = level.color;

    return Scaffold(
      backgroundColor: darkBg,
      // SafeArea para respetar el Notch de los iPhone nuevos
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. BOTÓN DE REGRESAR (Alineado arriba a la izquierda) ---
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // --- 2. CONTENIDO PRINCIPAL (Scrollable) ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // A. ICONO GIGANTE ANIMADO (Efecto Neon)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.1),
                          border: Border.all(
                            color: accentColor.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(level.icon, size: 60, color: accentColor),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // B. TÍTULO Y SUBTÍTULO
                    Text(
                      "NIVEL: ${level.title.toUpperCase()}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // C. TARJETA DE TEORÍA (System Logic)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(color: accentColor, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.terminal,
                                color: Colors.white70,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Explicacion del nivel",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            level.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // D. TARJETA DE ANALOGÍA (Pre-énfasis / Real World)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Ejemplo en el mundo real",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            level.analogy,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40), // Espacio extra al final
                  ],
                ),
              ),
            ),

            // --- 3. BOTÓN DE INICIAR MISIÓN (Fijo abajo) ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // PASO CRUCIAL:
                    // 1. Cargamos el nivel en el ViewModel (Sin redibujar esta pantalla)
                    final gameVM = Provider.of<GameViewModel>(
                      context,
                      listen: false,
                    );
                    gameVM.loadLevel(level);

                    // 2. Navegamos a la pantalla de Juego
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor, // Botón del color del nivel
                    foregroundColor: Colors.black, // Texto negro para contraste
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 10,
                    shadowColor: accentColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    "INICIAR MISIÓN >",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
