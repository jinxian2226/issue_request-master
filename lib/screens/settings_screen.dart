import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // App settings
  bool _pushNotifications = true;

  // Form controllers
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Passwords do not match!');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showPasswordChangeDialog();
    if (!confirmed) return;

    final authService = context.read<AuthService>();

    final success = await authService.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (success) {
      _showSuccessMessage('Password changed successfully!');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      _showErrorMessage(authService.error ?? 'Failed to change password');
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;

    final authService = context.read<AuthService>();
    await authService.logout();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  Future<bool> _showPasswordChangeDialog() async {
    final themeService = context.read<ThemeService>();
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Change Password',
          style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to change your password?',
          style: TextStyle(color: themeService.isDarkMode ? Colors.grey : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Change Password'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showLogoutDialog() async {
    final themeService = context.read<ThemeService>();
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: themeService.isDarkMode ? Colors.grey : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, AuthService>(
      builder: (context, themeService, authService, _) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
          appBar: AppBar(
            title: Text(
              'Settings & Profile',
              style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            iconTheme: IconThemeData(color: themeService.isDarkMode ? Colors.white : Colors.black),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current User Display
                _buildSectionCard(
                  title: 'Current User',
                  icon: Icons.account_circle,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2196F3),
                      child: Text(
                        (authService.currentUser?.isNotEmpty == true)
                            ? authService.currentUser![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      authService.currentUser ?? 'Unknown User',
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Logged in successfully',
                      style: TextStyle(
                        color: const Color(0xFF2196F3),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Password Section
                _buildSectionCard(
                  title: 'Change Password',
                  icon: Icons.lock_outline,
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _oldPasswordController,
                          label: 'Current Password',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          prefixIcon: Icons.lock_open,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Consumer<AuthService>(
                            builder: (context, authService, child) {
                              return ElevatedButton.icon(
                                onPressed: authService.isLoading ? null : _changePassword,
                                icon: authService.isLoading
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.key),
                                label: Text(authService.isLoading ? 'Changing...' : 'Change Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Settings Section
                _buildSectionCard(
                  title: 'App Settings',
                  icon: Icons.settings,
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive notifications for important updates',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme throughout the app',
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Actions Section
                _buildSectionCard(
                  title: 'Account Actions',
                  icon: Icons.exit_to_app,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFF2196F3),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeService.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: themeService.isDarkMode ? Colors.grey : Colors.grey[600]),
            prefixIcon: Icon(prefixIcon, color: themeService.isDarkMode ? Colors.grey : Colors.grey[600]),
            filled: true,
            fillColor: themeService.isDarkMode ? const Color(0xFF3C3C3C) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              color: themeService.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: themeService.isDarkMode ? Colors.grey : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        );
      },
    );
  }
}