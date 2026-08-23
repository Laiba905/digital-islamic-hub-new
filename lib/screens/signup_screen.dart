import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Registration failed"), backgroundColor: Colors.redAccent)
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
            // 🎯 Fixed: Safe deep dark gradient colors for dark mode background
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
                    "Create Account",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.green.shade900
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(15) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                            prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white60 : Colors.black45),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                          ),
                          validator: (val) => (val == null || val.isEmpty) ? "Name is required" : null,
                        ),
                        const SizedBox(height: 15),
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
                        const SizedBox(height: 15),
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
                          validator: (val) => (val == null || val.length < 6) ? "Password must be at least 6 characters" : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: _isLoading ? null : _handleSignUp,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          children: [
                            TextSpan(
                                text: "Login",
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