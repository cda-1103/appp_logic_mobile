import 'package:appp_logic_mobile/data/models/user_model.dart';
import 'package:appp_logic_mobile/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class LeaderboardViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  List<UserModel> _topUsers = [];
  bool _isLoading = false;

  List<UserModel> get topUsers => _topUsers;

  bool get isLoading => _isLoading;

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _topUsers = await _authRepo.getTopUsers();
    } catch (e) {
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}
