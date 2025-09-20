import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _currentUser;
  String? _error;

  // Mock user database - in production, this would be in Supabase or secure storage
  static final Map<String, String> _users = {
    "alex123": "password123",
    "john456": "mypassword",
    "sarah789": "123456",
    "admin": "admin123",
    "demo": "demo123",
  };

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get currentUser => _currentUser;
  String? get error => _error;

  // Initialize auth state - check if user was previously logged in
  Future<void> initializeAuth() async {
    _setLoading(true);

    // In a real app, check for stored auth token or session
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo purposes, start logged out
    _isLoggedIn = false;
    _currentUser = null;

    _setLoading(false);
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (!_users.containsKey(username)) {
        throw Exception("User does not exist!");
      }

      if (_users[username] != password) {
        throw Exception("Invalid password!");
      }

      _isLoggedIn = true;
      _currentUser = username;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    // Simulate logout delay
    await Future.delayed(const Duration(milliseconds: 300));

    _isLoggedIn = false;
    _currentUser = null;
    _clearError();

    _setLoading(false);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (_users[_currentUser] != oldPassword) {
        throw Exception("Current password is incorrect!");
      }

      if (newPassword.length < 6) {
        throw Exception("Password must be at least 6 characters!");
      }

      _users[_currentUser!] = newPassword;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}