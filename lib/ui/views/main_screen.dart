import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

import 'leaderboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista de tus pantallas
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Misiones

    const LeaderboardScreen(), // 1: Ranking

    const ProfileScreen(), // 2: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF00FF00);
    final darkBg = const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: darkBg,

      // EL BODY ES EL QUE CAMBIA
      body: _screens[_currentIndex],

      // LA BARRA SE QUEDA FIJA
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(
            0xFF010409,
          ), // Fondo más oscuro para la barra
          selectedItemColor: neonGreen,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              label: 'Missions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined), // Copa o Ranking
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
