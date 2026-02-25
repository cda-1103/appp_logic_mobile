import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  // Instancia del repositorio (La llave maestra)
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para que la UI lea los datos
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------
  // 🔄 RECARGAR USUARIO (Vital para actualizar XP y Niveles)
  // ---------------------------------------------------
  Future<void> reloadUser() async {
    if (_currentUser == null) return;

    try {
      // Pedimos los datos frescos a Firebase usando el ID actual
      final freshUser = await _authRepository.getUser(_currentUser!.uid);

      if (freshUser != null) {
        _currentUser = freshUser;
        // ¡GRITAMOS A LA APP QUE HAY DATOS NUEVOS!
        notifyListeners();
      }
    } catch (e) {
      print("Error recargando usuario: $e");
      // No mostramos error en UI para no molestar, es un proceso de fondo
    }
  }

  // ---------------------------------------------------
  // 🔐 INICIAR SESIÓN
  // ---------------------------------------------------
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authRepository.signIn(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString(); // "Contraseña incorrecta", etc.
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------
  // 📝 REGISTRARSE
  // ---------------------------------------------------
  Future<bool> register(
    String email,
    String password,
    String name,
    String lastName,
    String username,
    DateTime dateOfBirth,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Creamos el objeto usuario inicial
      final newUser = UserModel(
        uid: '', // Se llenará en el repositorio
        email: email,
        username: username,
        firstName: name,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        totalScore: 0,
        lives: 2, // <--- MODO HARDCORE: Empiezan con 2 vidas
        solvedLevels: 0,
        streak: 0,
        accuracy: 0.0,
      );

      // Lo enviamos a Firebase Auth y Firestore
      await _authRepository.singUp(
        email: email,
        password: password,
        userModel: newUser,
      );

      // Si todo sale bien, guardamos el usuario en memoria
      // (Asumimos que el UID ya se generó en el proceso)
      final uid = _authRepository.currentUser?.uid ?? '';
      _currentUser = newUser.copyWith(uid: uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  //cerrar sesion
  void logout() {
    _authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Helper para manejar el spinner de carga
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // LOGIN CON GOOGLE
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        // El usuario canceló la ventana
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Google Sign-In Failed: $e";
      _setLoading(false);
      return false;
    }
  }
}
