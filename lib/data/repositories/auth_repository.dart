import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // <-- IMPORTANTE PARA DETECTAR LA WEB
import '../../data/models/user_model.dart'; 

// Todas las operaciones que se van a realizar con la base de datos con respecto al usuario
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '247737032867-sscao453eefq1ftv67b3kq9ng0b32oa8.apps.googleusercontent.com' 
        : null, 
  );

  User? get currentUser => _auth.currentUser;

  // 1. LOGIN
  Future<UserModel> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("El usuario existe en Auth pero no tiene datos");
      }

      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 2. REGISTRO
  Future<void> singUp({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      UserModel newUser = userModel.copyWith(uid: userCredential.user!.uid);

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // 3. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    if (kIsWeb) {
      await _googleSignIn.signOut();
    } else {
      await _googleSignIn.signOut();
    }
  }

  // 4. ACTUALIZAR PROGRESO CON EL XP REAL
  Future<void> updateLevelProgress(
    String uid,
    String levelId,
    int score,
    int stars,
    int correctAnswers, 
    int totalQuestions, 
  ) {
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      // 1. LEER DATOS ACTUALES
      final currentTotalScore = (stats['total_score'] ?? 0) as int;
      final currentSolved = (stats['solved_levels'] ?? 0) as int;
      final currentStreak = (stats['current_streak'] ?? 0) as int;

      // Para calcular accuracy necesitamos los históricos acumulados
      final historyCorrect = (stats['history_correct'] ?? 0) as int;
      final historyTotal = (stats['history_questions'] ?? 0) as int;

      // 2. CALCULAR NUEVOS VALORES
      final newHistoryCorrect = historyCorrect + correctAnswers;
      final newHistoryTotal = historyTotal + totalQuestions;

      // Fórmula de Efectividad: (Correctas / Totales) * 100
      double newAccuracy = 0.0;
      if (newHistoryTotal > 0) {
        newAccuracy = (newHistoryCorrect / newHistoryTotal) * 100;
      }

      // 3. ACTUALIZAR BASE DE DATOS
      transaction.update(userRef, {
        'stats.total_score': currentTotalScore + score,
        'stats.solved_levels': currentSolved + 1,
        'stats.current_streak': currentStreak + 1, 
        'stats.accuracy': newAccuracy, 
        'stats.history_correct': newHistoryCorrect,
        'stats.history_questions': newHistoryTotal,

        'level_progress.$levelId': {
          'status': 'completed',
          'score': score,
          'stars': stars,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    });
  }

  // 5. OBTENER LA TABLA DE LOS 20 MEJORES
  Future<List<UserModel>> getTopUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('stats.total_score', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error obteniendo la tabla de lideres: $e");
      return [];
    }
  }

  // 6. OBTENER USUARIO
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print("Error obteniendo usuario: $e");
      return null;
    }
  }

  // 7. ACTUALIZAR ESTATUS DE VIDA
  Future<void> updateLives(String uid, int newLives) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'stats.lives': newLives,
      });
    } catch (e) {
      print("Error actualizando estatus de vida: $e");
    }
  }

  // 8. RECUPERAR CONTRASEÑA
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error al restablecer contraseña: $e");
      rethrow; // Para que el ViewModel pueda atrapar y traducir el error
    }
  }

  // 9. GOOGLE SIGN IN //ios y web
  Future<UserModel?> signInWithGoogle() async {
    try {
      // A. Iniciar flujo interactivo de Google (Popup en Web, Modal en Móvil)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló o cerró la ventana

      // B. Obtener credenciales (Tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // C. Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // D. VERIFICAR SI YA EXISTE EN FIRESTORE
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // SI EL USUARIO ES NUEVO: CREARLE EL DOCUMENTO CON DATOS POR DEFECTO
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.displayName ?? 'Agente', 
            firstName: user.displayName?.split(' ').first ?? 'Agente',
            lastName: '',
            dateOfBirth: DateTime.now(), // Dato desconocido por los momentos
            totalScore: 0,
            lives: 2,
            streak: 0,
            solvedLevels: 0,
            accuracy: 0.0,
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        } else {
          //SI YA EXISTE: DEVOLVER SUS DATOS
          return UserModel.fromMap(userDoc.data()!, user.uid);
        }
      }
    } catch (e) {
      print("Error Google Sign In: $e");
      throw Exception("Ocurrió un error con Google Sign-In: $e");
    }
    return null;
  }
}