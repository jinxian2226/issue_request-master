// Test script to verify registration and login flow
// Run this in your Flutter app to test the authentication

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _testResults = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testRegistration() async {
    setState(() {
      _testResults = 'Testing registration...\n';
    });

    final authService = context.read<AuthService>();

    try {
      final success = await authService.register(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _testResults += success
            ? '✅ Registration successful!\n'
            : '❌ Registration failed: ${authService.error}\n';
      });

      if (success) {
        setState(() {
          _testResults += 'User is now logged in: ${authService.currentUser}\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ Registration error: $e\n';
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _testResults = 'Testing login...\n';
    });

    final authService = context.read<AuthService>();

    try {
      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _testResults += success
            ? '✅ Login successful!\n'
            : '❌ Login failed: ${authService.error}\n';
      });

      if (success) {
        setState(() {
          _testResults += 'Logged in as: ${authService.currentUser}\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ Login error: $e\n';
      });
    }
  }

  Future<void> _testLogout() async {
    setState(() {
      _testResults = 'Testing logout...\n';
    });

    final authService = context.read<AuthService>();

    try {
      await authService.logout();
      setState(() {
        _testResults += '✅ Logout successful!\n';
        _testResults += 'User logged out: ${authService.isLoggedIn}\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Logout error: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Test Registration'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Test Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Test Logout'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'Test results will appear here...' : _testResults,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
