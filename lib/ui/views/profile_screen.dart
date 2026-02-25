import 'package:appp_logic_mobile/core/services/level_uploader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthViewModel>(context, listen: false).reloadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;

    final neonGreen = const Color(0xFF00FF00);
    final darkBg = const Color(0xFF0D1117);

    if (user == null) {
      return Scaffold(
        backgroundColor: darkBg,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    final nextLevelXp = user.nextLevelXp;
    final currentXp = user.totalScore;
    final progress = user.levelProgressPercentage;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // 2. AQUÍ ESTÁ EL CAMBIO EN EL APPBAR
        actions: [
          IconButton(
            // Cambiado a nube y color verde para resaltar que es una acción de admin
            icon: Icon(Icons.cloud_upload, color: neonGreen),
            onPressed: () async {
              // A. Feedback visual: "Subiendo..."
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'UPLOADING DATA TO MAINFRAME...',
                    style: TextStyle(fontFamily: 'Courier'),
                  ),
                  backgroundColor: Colors.grey[800],
                  duration: const Duration(seconds: 1),
                ),
              );

              await LevelUploader.uploadLevels();

              // C. Confirmación de éxito
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'SYSTEM UPDATED SUCCESSFULLY',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: neonGreen.withOpacity(0.8),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- HEADER (Avatar) ---
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1F2937),
              child: Icon(Icons.person, size: 50, color: neonGreen),
            ),
            const SizedBox(height: 16),
            Text(
              user.username.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Courier',
              ),
            ),
            Text(
              user.rankTitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Courier',
              ),
            ),

            const SizedBox(height: 32),

            // --- LEVEL PROGRESS BAR ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LEVEL ${user.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                      Text(
                        '$currentXp / $nextLevelXp XP',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(neonGreen),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user.xpToNextLevel} XP to next rank',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- STATS GRID ---
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildStatCard(
                  'RESUELTOS',
                  '${user.solvedLevels}',
                  Icons.check_circle_outline,
                  Colors.blue,
                ),
                _buildStatCard(
                  'RACHA',
                  '${user.streak}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStatCard(
                  'EFECTIVIDAD',
                  '${user.accuracy.toStringAsFixed(0)}%',
                  Icons.gps_fixed,
                  Colors.purpleAccent,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                onPressed: () async {
                  authVM.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D1B1B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
