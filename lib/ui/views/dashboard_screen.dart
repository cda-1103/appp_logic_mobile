import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/level_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'level_intro_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<LevelModel>> _levelsFuture;

  @override
  void initState() {
    super.initState();
    final levelRepo = Provider.of<LevelRepository>(context, listen: false);
    _levelsFuture = levelRepo.getLevels();
  }

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
      // --- CAMBIO PRINCIPAL AQUÍ ---
      // Usamos una Column para poner el Header arriba y la lista abajo
      body: Column(
        children: [
          // 1. EL ENCABEZADO DE USUARIO (Estilo de la foto)
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
    );
  }

  // --- WIDGET NUEVO: ENCABEZADO DE USUARIO ---
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
                  user.rankTitle ??
                      "Aprendiz Junior", // Rango (si es null usa default)
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

          // C. Píldora de XP (Estilo de la foto)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // Fondo gris oscuro
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: neonGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: neonGreen, size: 16), // Rayito
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

  // --- WIDGET TARJETA DE NIVEL (Igual que antes) ---
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
