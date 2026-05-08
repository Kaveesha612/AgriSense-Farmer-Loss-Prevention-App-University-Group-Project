import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool isLoading = false;
  bool rememberMe = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000'; // Android emulator
    } else {
      return 'http://localhost:5000'; // iOS simulator, web and desktop
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe = prefs.getBool('rememberMe') ?? false;
    if (rememberMe) {
      emailController.text = prefs.getString('savedEmail') ?? '';
    }
    setState(() {});
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
    if (value) {
      await prefs.setString('savedEmail', emailController.text.trim());
    } else {
      await prefs.remove('savedEmail');
    }
  }

  Future<void> _handleSuccessfulLogin({
    required String userId,
    required String userName,
    required String token,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userName', userName);
    if (email != null) {
      await prefs.setString('userEmail', email);
    }

    if (rememberMe) {
      await prefs.setBool('rememberMe', true);
      if (email != null) {
        await prefs.setString('savedEmail', email);
      }
    } else {
      await prefs.remove('rememberMe');
      await prefs.remove('savedEmail');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }
      final auth = await googleUser.authentication;
      final token = auth.idToken ?? auth.accessToken ?? 'google:${googleUser.id}';
      await _handleSuccessfulLogin(
        userId: googleUser.id,
        userName: googleUser.displayName ?? googleUser.email,
        token: token,
        email: googleUser.email,
      );
    } catch (e) {
      _showErrorDialog('Google login failed. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => isLoading = true);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'name,email',
        );
        final token = result.accessToken?.toString() ?? 'facebook:${userData['id'] ?? ''}';
        await _handleSuccessfulLogin(
          userId: userData['id']?.toString() ?? '',
          userName: userData['name']?.toString() ?? userData['email']?.toString() ?? 'Facebook User',
          token: token,
          email: userData['email']?.toString(),
        );
      } else if (result.status == LoginStatus.cancelled) {
        _showErrorDialog('Facebook login was cancelled.');
      } else {
        _showErrorDialog('Facebook login failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Facebook login failed. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'), // Use dynamic base URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (rememberMe) {
          await _saveRememberMe(true);
        }
        await _handleSuccessfulLogin(
          userId: data['_id'],
          userName: data['name'],
          token: data['token'],
          email: data['email'],
        );
      } else {
        final error = jsonDecode(response.body);
        _showErrorDialog(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> registerUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (rememberMe) {
          await _saveRememberMe(true);
        }
        await _handleSuccessfulLogin(
          userId: data['_id'],
          userName: data['name'],
          token: data['token'],
          email: data['email'],
        );
      } else {
        final error = jsonDecode(response.body);
        _showErrorDialog(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showErrorDialog('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboardingBG.png',
              fit: BoxFit.cover,
            ),
          ),

          // Header - Safely positioned using screen proportions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.12),
                  Image.asset(
                    'assets/images/AGRISENSEWLOGO.png',
                    width: screenWidth * 0.4,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Get Started now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Text(
                    'Create an account or log in to explore about our app',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sliding White Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.7,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 THE NEW INTERACTIVE SLIDING SWITCH 🌟
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // 1. The Sliding White Box
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut, // Smooth, snappy feel
                            alignment: isLogin
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 0.5, // Takes exactly half the width
                              heightFactor: 1.0,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  // Optional: A tiny shadow makes it pop like a real physical button
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 2. The Clickable Text overlay
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isLogin = true),
                                  behavior: HitTestBehavior
                                      .opaque, // Ensures the whole box is clickable
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        color: const Color(0xFF081C15),
                                        fontWeight: isLogin
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      child: const Text("Log In"),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isLogin = false),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        color: const Color(0xFF081C15),
                                        fontWeight: !isLogin
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      child: const Text("Sign Up"),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (!isLogin) ...[
                      const Text(
                        "Full Name",
                        style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        "Enter your full name",
                        Icons.person_outline,
                        controller: nameController,
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      "Email",
                      style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      "Enter your email",
                      Icons.email_outlined,
                      controller: emailController,
                    ),

                    const SizedBox(height: 20),

                    if (!isLogin) ...[
                      const Text(
                        "Phone",
                        style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        "Enter your phone number",
                        Icons.phone_outlined,
                        controller: phoneController,
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      "Password",
                      style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      "Enter your password",
                      Icons.lock_outline,
                      controller: passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: rememberMe,
                                onChanged: (val) {
                                  final newValue = val ?? false;
                                  setState(() => rememberMe = newValue);
                                  _saveRememberMe(newValue);
                                },
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            const Text(
                              " Remember me",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (isLogin)
                          const Text(
                            "Forgot Password ?",
                            style: TextStyle(
                              color: Color(0xFF1B4332),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Gradient Action Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF081C15), Color(0xFF1B4332)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (isLogin) {
                                  loginUser();
                                } else {
                                  registerUser();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLogin ? "Log In" : "Sign Up",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.black12)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Or",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.black12)),
                      ],
                    ),

                    const SizedBox(height: 25),

                    _buildSocialButton(
                      "Continue with Google",
                      "assets/images/google.png",
                      _signInWithGoogle,
                    ),
                    const SizedBox(height: 15),
                    _buildSocialButton(
                      "Continue with Facebook",
                      "assets/images/facebook.png",
                      _signInWithFacebook,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Notice: The old _buildToggleButton is gone entirely!

  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4332)),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    String assetPath,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error_outline, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
