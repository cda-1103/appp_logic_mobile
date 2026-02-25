import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/leaderboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Apenas entramos, pedimos la lista al ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaderboardViewModel>(
        context,
        listen: false,
      ).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardVM = Provider.of<LeaderboardViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final currentUser = authVM.currentUser;
    final neonGreen = const Color(0xFF00FF00);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Top 10 Jugadores",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'courier',
            color: Color(0xFF00FF00),
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: leaderboardVM.isLoading
          ? Center(child: CircularProgressIndicator(color: neonGreen))
          : Column(
              children: [
                // 1. TOP 3 (Podio)
                if (leaderboardVM.topUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Segundo Lugar
                        if (leaderboardVM.topUsers.length > 1)
                          _buildPodiumItem(leaderboardVM.topUsers[1], 2, 80),

                        // Primer Lugar (Más grande y al centro)
                        _buildPodiumItem(leaderboardVM.topUsers[0], 1, 110),

                        // Tercer Lugar
                        if (leaderboardVM.topUsers.length > 2)
                          _buildPodiumItem(leaderboardVM.topUsers[2], 3, 80),
                      ],
                    ),
                  ),

                // 2. LISTA DEL RESTO (Del 4 en adelante)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF161B22),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: leaderboardVM.topUsers.length > 3
                          ? leaderboardVM.topUsers.length - 3
                          : 0,
                      itemBuilder: (context, index) {
                        final realIndex =
                            index + 3; // Porque los primeros 3 están arriba
                        final user = leaderboardVM.topUsers[realIndex];
                        final isMe = user.uid == currentUser?.uid;

                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? neonGreen.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isMe
                                ? Border.all(color: neonGreen.withOpacity(0.5))
                                : null,
                          ),
                          child: ListTile(
                            leading: Text(
                              "${realIndex + 1}",
                              style: TextStyle(
                                color: isMe ? neonGreen : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              "${user.totalScore} XP",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widget auxiliar para las medallas del podio
  Widget _buildPodiumItem(UserModel user, int position, double size) {
    Color ringColor;
    double fontSize;

    if (position == 1) {
      ringColor = const Color(0xFF00FF00); // Oro/Verde Hacker
      fontSize = 18;
    } else if (position == 2) {
      ringColor = Colors.blueAccent; // Plata
      fontSize = 14;
    } else {
      ringColor = Colors.orangeAccent; // Bronce
      fontSize = 14;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 3),
            ),
            child: CircleAvatar(
              radius: size / 2.5,
              backgroundColor: Colors.white10,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ringColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$position",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${user.totalScore} XP",
            style: TextStyle(
              color: ringColor,
              fontSize: fontSize - 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
