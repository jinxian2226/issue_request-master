import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _currentUser;
  String? _error;

  // Get Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get currentUser => _currentUser;
  String? get error => _error;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);

    try {
      // Set up auth state listener
      _setupAuthListener();

      // Check if there's an existing session
      final session = _supabase.auth.currentSession;

      if (session != null && session.user != null) {
        await _updateUserInfo(session.user!);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      print('Error initializing auth: $e');
      _isLoggedIn = false;
      _currentUser = null;
    }

    _setLoading(false);
  }

  // Update user information
  Future<void> _updateUserInfo(User user) async {
    _isLoggedIn = true;

    // Get username from user_profiles table
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['username'] != null) {
        _currentUser = response['username'] as String;
      } else {
        // If profile doesn't exist, create it
        await _createMissingProfile(user);
        _currentUser = 'User';
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      _currentUser = 'User';
    }
  }

  // Create missing profile for user
  Future<void> _createMissingProfile(User user) async {
    try {
      // Extract username from email
      final username = user.email?.split('@')[0] ?? 'user';

      await _supabase.from('user_profiles').insert({
        'id': user.id,
        'username': username,
        'display_name': username,
        'role': 'user',
        'is_active': true,
      });

      _currentUser = username;
      print('Created missing profile for user: $username');
    } catch (e) {
      print('Error creating missing profile: $e');
    }
  }

  // Login with username/password (converts to Gmail email internally)
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Use Gmail domain for authentication
      String email = '$username@gmail.com';

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _updateUserInfo(response.user!);
        _setLoading(false);
        return true;
      } else {
        throw Exception("Invalid login credentials!");
      }
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
        case 'Email not confirmed':
          _error = "Invalid username or password!";
          break;
        case 'User not found':
          _error = "User does not exist!";
          break;
        case 'Too many requests':
          _error = "Too many login attempts. Please try again later.";
          break;
        default:
          _error = e.message ?? "Login failed!";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  // Register new user with username/password
  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters!");
      }

      if (username.length < 3) {
        throw Exception("Username must be at least 3 characters!");
      }

      // Check if username already exists
      final existingUser = await _supabase
          .from('user_profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception("Username already exists!");
      }

      // Use Gmail domain for authentication
      String email = '$username@gmail.com';

      print('Attempting to register: $email with metadata: $username');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': username,
          'role': 'user',
        },
      );

      if (response.user != null) {
        print('User created successfully: ${response.user!.id}');

        // Wait a moment for the trigger to process
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify the profile was created
        await _updateUserInfo(response.user!);

        // If profile still doesn't exist, create it manually
        if (_currentUser == 'User') {
          await _createMissingProfile(response.user!);
        }

        _setLoading(false);
        return true;
      } else {
        throw Exception("Registration failed!");
      }
    } on AuthException catch (e) {
      switch (e.message) {
        case 'User already registered':
          _error = "Email already exists! Try a different username.";
          break;
        case 'Password should be at least 6 characters':
          _error = "Password must be at least 6 characters!";
          break;
        case 'Signup disabled':
          _error = "Registration is currently disabled.";
          break;
        default:
          _error = e.message ?? "Registration failed!";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = "Please login first!";
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (newPassword.length < 6) {
        throw Exception("Password must be at least 6 characters!");
      }

      // Verify the old password by trying to sign in again
      final email = currentUser.email!;

      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: oldPassword,
        );
      } catch (e) {
        throw Exception("Current password is incorrect!");
      }

      // Update password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        _error = "Current password is incorrect!";
      } else {
        _error = e.message ?? "Password change failed!";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }

    _isLoggedIn = false;
    _currentUser = null;
    _clearError();
    _setLoading(false);
  }

  // Listen to auth state changes
  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;

      if (session != null && session.user != null) {
        await _updateUserInfo(session.user!);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
      }

      notifyListeners();
    });
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