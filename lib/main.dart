import 'package:appp_logic_mobile/data/repositories/level_repository.dart';
import 'package:appp_logic_mobile/data/repositories/auth_repository.dart'; // <--- 1. IMPORTANTE: Agrega este import
import 'package:appp_logic_mobile/ui/viewmodels/game_viewmodel.dart';
import 'package:appp_logic_mobile/ui/viewmodels/leaderboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

// Importaciones de las vistas y viewmodels
import 'ui/viewmodels/auth_viewmodel.dart';
import 'ui/views/login_screen.dart';
import 'ui/viewmodels/level_viewmodel.dart';
 void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //repositorio cin los datos
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<LevelRepository>(create: (_) => LevelRepository()),

        // viemodels de la logica
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => GameViewModel(
            authRepo: Provider.of<AuthRepository>(context, listen: false),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => LevelViewModel(
          ),
        ),

        ChangeNotifierProvider(create: (_) => LeaderboardViewModel()),
      ],
      child: MaterialApp(
        title: 'BUCLE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          primaryColor: const Color(0xFF00FF00),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
