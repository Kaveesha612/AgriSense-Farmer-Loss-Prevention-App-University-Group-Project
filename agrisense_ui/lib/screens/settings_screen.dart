import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _appNotifications = true;
  bool _autoUpdates = true;
  String _selectedLanguage = 'en';
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  final Map<String, String> _languages = {
    'en': 'English',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
  };

  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
    _fetchSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoUpdates = prefs.getBool('autoUpdates') ?? true;
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Not signed in. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _appNotifications = userData['notificationsEnabled'] ?? true;
          _selectedLanguage = userData['preferredLanguage'] ?? 'en';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load settings from server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAutoUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoUpdates', value);
    setState(() {
      _autoUpdates = value;
    });
  }

  Future<void> _updateBackendSettings({
    bool? notificationsEnabled,
    String? language,
  }) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Not signed in. Please log in again.';
          _isUpdating = false;
        });
        return;
      }

      final body = <String, dynamic>{};
      if (notificationsEnabled != null) {
        body['notificationsEnabled'] = notificationsEnabled;
      }
      if (language != null) {
        body['preferredLanguage'] = language;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      } else {
        final error = json.decode(response.body);
        setState(() {
          _errorMessage = error['message'] ?? 'Unable to update settings';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating settings: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Not signed in. Please log in again.';
          _isUpdating = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      } else {
        final error = json.decode(response.body);
        _showErrorDialog(error['message'] ?? 'Unable to update password');
      }
    } catch (e) {
      _showErrorDialog('Error updating password: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This action is permanent. Do you want to delete your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Not signed in. Please log in again.';
          _isUpdating = false;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _clearSession();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (route) => false,
          );
        }
      } else {
        final error = json.decode(response.body);
        setState(() {
          _errorMessage = error['message'] ?? 'Unable to delete account';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting account: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  Future<void> _logout() async {
    await _clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showPasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final current = currentPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                final confirm = confirmPasswordController.text.trim();
                if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  _showErrorDialog('Please fill all password fields');
                  return;
                }
                if (newPass != confirm) {
                  _showErrorDialog(
                    'New password and confirmation do not match',
                  );
                  return;
                }
                Navigator.of(context).pop();
                _updatePassword(current, newPass);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Support'),
          content: const Text(
            'For assistance, email support@agrisense.com or call +94 77 123 4567.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B5B43)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          _buildToggleTile(
            title: 'App Notifications',
            subtitle: 'Receive mobile app notifications',
            value: _appNotifications,
            onChanged: (val) {
              setState(() {
                _appNotifications = val;
              });
              _updateBackendSettings(notificationsEnabled: val);
            },
          ),
          _buildDivider(),

          _buildRowTile(
            title: 'Preferred Language',
            subtitle: _languages[_selectedLanguage] ?? 'English',
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  _updateBackendSettings(language: value);
                }
              },
              underline: const SizedBox.shrink(),
            ),
          ),
          _buildDivider(),

          _buildToggleTile(
            title: 'Auto Updates',
            subtitle: 'Automatically update when available',
            value: _autoUpdates,
            onChanged: (val) {
              _saveAutoUpdates(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? 'Auto updates enabled' : 'Auto updates disabled',
                  ),
                ),
              );
            },
          ),
          _buildDivider(),

          _buildArrowTile(
            title: 'Password',
            subtitle: 'Update your password',
            onTap: _showPasswordDialog,
          ),
          _buildDivider(),

          _buildArrowTile(
            title: 'Need Help?',
            subtitle: 'Contact our support center',
            onTap: _showHelpDialog,
          ),
          _buildDivider(),

          _buildActionTile(
            title: 'Log Out',
            subtitle: 'Log out from AgriSense',
            titleColor: const Color(0xFFE53935),
            onTap: _logout,
          ),
          _buildDivider(),

          _buildActionTile(
            title: 'Delete My Account',
            subtitle: 'Delete your AgriSense account',
            titleColor: const Color(0xFFE53935),
            onTap: _deleteAccount,
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF65C48A),
          ),
        ],
      ),
    );
  }

  Widget _buildRowTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildArrowTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
    );
  }
}
