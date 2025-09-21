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
  // User profile data
  String _username = '';
  String _email = '';

  // App settings
  bool _pushNotifications = true;

  // Form controllers
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  void _initializeProfile() {
    final authService = context.read<AuthService>();
    _username = authService.currentUser ?? 'User';
    _email = '${_username}@example.com';

    _usernameController.text = _username;
    _emailController.text = _email;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _username = _usernameController.text;
      _email = _emailController.text;
    });

    _showSuccessMessage('Profile updated successfully!');
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await _showPasswordChangeDialog();
    if (!confirmed) return;

    final authService = context.read<AuthService>();

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Passwords do not match!');
      return;
    }

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
      Navigator.pushReplacementNamed(context, '/login');
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
            child: const Text('Yes, Change Password'),
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
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showNotificationDialog() {
    final themeService = context.read<ThemeService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Color(0xFF2196F3),
            ),
            const SizedBox(width: 8),
            Text(
              'Notifications',
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Push notifications have been enabled! You will now receive important updates and alerts.',
          style: TextStyle(
            color: themeService.isDarkMode ? Colors.grey : Colors.grey[700],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
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
                // Profile Section
                _buildSectionCard(
                  title: 'Profile Information',
                  icon: Icons.person_outline,
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email,
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
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
                          child: ElevatedButton.icon(
                            onPressed: _changePassword,
                            icon: const Icon(Icons.key),
                            label: const Text('Change Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
                          if (value) {
                            _showNotificationDialog();
                          }
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme throughout the app',
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.setTheme(value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Section
                _buildSectionCard(
                  title: 'Account Actions',
                  icon: Icons.logout,
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
                const SizedBox(height: 32),
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
        return Card(
          color: themeService.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF2196F3), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
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
          style: TextStyle(color: themeService.isDarkMode ? Colors.white : Colors.black),
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: themeService.isDarkMode ? Colors.grey : Colors.grey[600]),
            prefixIcon: Icon(prefixIcon, color: themeService.isDarkMode ? Colors.grey : Colors.grey[600]),
            filled: true,
            fillColor: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: themeService.isDarkMode ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2196F3)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        );
      },
    );
  }
}