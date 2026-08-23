import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } on FirebaseAuthException catch (e) {
        String message = "Authentication failed";
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          message = "You are not registered. Please create an account first.";
        } else if (e.code == 'wrong-password') {
          message = "Incorrect password. Please try again.";
        }
        _showSnackBar(message, isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 🔒 Function to handle Forgot Password action
  void _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains("@")) {
      _showSnackBar("Please enter a valid email address first to reset password.", isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnackBar("Password reset link sent successfully to your email!", isError: false);
    } catch (e) {
      _showSnackBar("Error sending reset link: ${e.toString()}", isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF003D33), const Color(0xFF001F1A)]
                : [Colors.green.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    "Digital Islamic Hub",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.green.shade900
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(15) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Text(
                            "Welcome Back",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                            prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.white60 : Colors.black45),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                          ),
                          validator: (val) => (val == null || !val.contains("@")) ? "Enter a valid email" : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                            prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white60 : Colors.black45),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white60 : Colors.black45),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                          validator: (val) => (val == null || val.isEmpty) ? "Password is required" : null,
                        ),

                        // 🔑 FORGOT PASSWORD BUTTON (Perfect Alignment with Contrast Check)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF81C784) : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                    child: Text.rich(
                      TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          children: [
                            TextSpan(
                                text: "Sign Up",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF81C784) : Colors.green.shade700)
                            )
                          ]
                      ),
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
}