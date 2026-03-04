import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NECESARIO PARA LEER LOS ERRORES
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  // Instancia del repositorio 
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para que la UI lea los datos
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  //TRADUCTOR DE ERRORES DE FIREBASE A ESPAÑOL

  String _translateFirebaseError(dynamic e) {
    // Si el error viene directamente de Firebase Auth
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Usuario o contraseña incorrectos. Verifica tus datos.';
        case 'email-already-in-use':
          return 'Este correo electrónico ya se encuentra registrado.';
        case 'weak-password':
          return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada por un administrador.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Por seguridad, intenta más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Por favor revisa tu internet.';
        case 'operation-not-allowed':
          return 'Operación no permitida. Contacta a soporte.';
        default:
          return 'Ocurrió un error inesperado. Intenta de nuevo.';
      }
    } 
    
    // Si el repositorio encapsuló el error en un Exception (String general)
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('invalid-credential') || errorStr.contains('wrong-password') || errorStr.contains('user-not-found')) {
      return 'Usuario o contraseña incorrectos. Verifica tus datos.';
    } else if (errorStr.contains('email-already-in-use')) {
      return 'Este correo electrónico ya se encuentra registrado.';
    } else if (errorStr.contains('network-request-failed')) {
      return 'Error de conexión. Por favor revisa tu internet.';
    }
    
    // Si es un error desconocido
    return 'Error del sistema: ${e.toString()}';
  }


  // RECARGAR USUARIO (Vital para actualizar XP y Niveles)

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

  
  // INICIAR SESIÓN
 
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authRepository.signIn(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      // ---> APLICAMOS EL TRADUCTOR DE ERRORES <---
      _errorMessage = _translateFirebaseError(e); 
      _setLoading(false);
      return false;
    }
  }


  // REGISTRARSE

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
        lives: 2, //
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
      final uid = _authRepository.currentUser?.uid ?? '';
      _currentUser = newUser.copyWith(uid: uid);

      _setLoading(false);
      return true;
    } catch (e) {
      // ---> APLICAMOS EL TRADUCTOR DE ERRORES <---
      _errorMessage = _translateFirebaseError(e);
      _setLoading(false);
      return false;
    }
  }

  // CERRAR SESIÓN

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

  // RECUPERAR CONTRASEÑA

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      // ---> APLICAMOS EL TRADUCTOR DE ERRORES <---
      _errorMessage = _translateFirebaseError(e);
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
      _errorMessage = "No se pudo iniciar sesión con Google. Intenta de nuevo.";
      _setLoading(false);
      return false;
    }
  }
}