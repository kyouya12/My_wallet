import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final AuthController _authController = AuthController();
  final ProfileController _profileController = ProfileController();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get batasBudget => _currentUser?.batasBudget ?? 0;
  String get userId => _currentUser?.userId ?? '';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authController.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    DateTime? tanggalLahir,
    String? jenisKelamin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authController.register(
        namaLengkap: namaLengkap,
        email: email,
        password: password,
        noHp: noHp,
        tanggalLahir: tanggalLahir,
        jenisKelamin: jenisKelamin,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? namaLengkap,
    String? email,
    String? noHp,
    String? fotoProfil,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _profileController.updateProfile(
        userId: _currentUser!.userId,
        namaLengkap: namaLengkap,
        email: email,
        noHp: noHp,
        fotoProfil: fotoProfil,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget(double newBudget) async {
    if (_currentUser == null) return false;

    try {
      _currentUser = await _profileController.updateBudget(
        _currentUser!.userId,
        newBudget,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAllData() async {
    if (_currentUser == null) return;
    await _profileController.deleteAllData(_currentUser!.userId);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
