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
        print('Existing session found for user: ${session.user!.id}');
        await _updateUserInfo(session.user!);
      } else {
        print('No existing session found');
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

  // Update user information from Supabase metadata
  Future<void> _updateUserInfo(User user) async {
    _isLoggedIn = true;

    try {
      // Extract username from Supabase user metadata
      if (user.userMetadata != null && user.userMetadata!['username'] != null) {
        _currentUser = user.userMetadata!['username'] as String;
        print('Username extracted from metadata: $_currentUser');
      } else {
        // Fallback: extract from email
        _currentUser = user.email?.split('@')[0] ?? 'User';
        print('Username extracted from email: $_currentUser');
      }

      print('User logged in successfully: $_currentUser');
    } catch (e) {
      print('Error extracting user info: $e');
      _currentUser = 'User';
    }
  }

  // Manually confirm user email (helper function)
  Future<void> _confirmUserEmail(String email) async {
    try {
      await _supabase.functions.invoke(
        'confirm_user_email',
        body: {'email': email},
      );
      print('Email confirmation function called for: $email');
    } catch (e) {
      print('Error calling email confirmation function: $e');
      // Fallback: try direct database update
      try {
        await _supabase
            .from('auth.users')
            .update({'email_confirmed_at': DateTime.now().toIso8601String()})
            .eq('email', email);
        print('Email confirmed via direct database update');
      } catch (dbError) {
        print('Database update failed: $dbError');
        throw Exception('Could not confirm email');
      }
    }
  }


  // Login with username/password (converts to Gmail email internally)
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Use Gmail domain for authentication
      String email = '$username@gmail.com';

      print('=== LOGIN ATTEMPT ===');
      print('Username: $username');
      print('Email: $email');
      print('Password length: ${password.length}');

      // First, let's check if the user exists in Supabase
      try {
        final userCheck = await _supabase
            .from('auth.users')
            .select('email, email_confirmed_at')
            .eq('email', email)
            .maybeSingle();

        if (userCheck != null) {
          print('User found in database: ${userCheck['email']}');
          print('Email confirmed: ${userCheck['email_confirmed_at'] != null}');
        } else {
          print('User NOT found in database for email: $email');
        }
      } catch (e) {
        print('Error checking user in database: $e');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Auth response: ${response.user != null ? 'Success' : 'Failed'}');
      if (response.user != null) {
        print('User ID: ${response.user!.id}');
        print('User email: ${response.user!.email}');
        print('Email confirmed: ${response.user!.emailConfirmedAt != null}');
        print('User metadata: ${response.user!.userMetadata}');
      }

      if (response.user != null) {
        print('Login successful for user: ${response.user!.id}');
        await _updateUserInfo(response.user!);
        _setLoading(false);
        return true;
      } else {
        throw Exception("Invalid login credentials!");
      }
    } on AuthException catch (e) {
      print('AuthException during login: ${e.message}');
      print('AuthException code: ${e.statusCode}');
      print('AuthException details: ${e.toString()}');

      switch (e.message) {
        case 'Invalid login credentials':
          _error = "Invalid username or password!";
          break;
        case 'Email not confirmed':
          _error = "Account created but email not confirmed. Please try logging in again.";
          break;
        case 'User not found':
          _error = "Username does not exist!";
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
      print('General error during login: $e');
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

      // Use Gmail domain for authentication
      String email = '$username@gmail.com';

      print('=== REGISTRATION ATTEMPT ===');
      print('Username: $username');
      print('Email: $email');
      print('Password length: ${password.length}');

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
        print('User email: ${response.user!.email}');
        print('Email confirmed: ${response.user!.emailConfirmedAt != null}');
        print('User metadata: ${response.user!.userMetadata}');

        // If email is not confirmed, try to confirm it manually
        if (response.user!.emailConfirmedAt == null) {
          print('Email not confirmed, attempting to confirm manually...');
          try {
            await _confirmUserEmail(email);
            print('Email confirmed successfully');
          } catch (e) {
            print('Could not confirm email automatically: $e');
            // Continue anyway - the user might still be able to login
          }
        }

        // Update user info to set login state
        await _updateUserInfo(response.user!);

        _setLoading(false);
        return true;
      } else {
        throw Exception("Registration failed!");
      }
    } on AuthException catch (e) {
      print('AuthException during registration: ${e.message}');
      switch (e.message) {
        case 'User already registered':
          _error = "Username already exists! Try a different username.";
          break;
        case 'Password should be at least 6 characters':
          _error = "Password must be at least 6 characters!";
          break;
        case 'Signup disabled':
          _error = "Registration is currently disabled.";
          break;
        case 'Email not confirmed':
          _error = "Registration successful! You can now login.";
          break;
        default:
          _error = e.message ?? "Registration failed!";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print('General error during registration: $e');
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