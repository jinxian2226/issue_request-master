import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegistering = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();

    final success = await authService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();

    final success = await authService.register(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! You are now logged in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _usernameController.clear();
      _passwordController.clear();
    });
    context.read<AuthService>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.inventory,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'PartInventory Pro',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Spare Parts Inventory Management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Mode Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isRegistering) _toggleMode();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isRegistering ? const Color(0xFF2196F3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isRegistering ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isRegistering) _toggleMode();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isRegistering ? const Color(0xFF2196F3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Register',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isRegistering ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username Field
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      if (_isRegistering && value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isRegistering && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error Display
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      if (authService.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authService.error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Action Button
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authService.isLoading
                              ? null
                              : _isRegistering ? _register : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: authService.isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Text(
                            _isRegistering ? 'Create Account' : 'Login',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isRegistering ? Icons.person_add : Icons.info_outline,
                              color: const Color(0xFF2196F3),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRegistering ? 'Create New Account' : 'Simple Login',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegistering
                              ? 'Just enter a username and password to create your account. No email required!'
                              : 'Login with just your username and password. Simple and secure.',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '• Username: minimum 3 characters\n• Password: minimum 6 characters',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}