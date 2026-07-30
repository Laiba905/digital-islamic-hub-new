import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'admin_dashboard_screen.dart'; // 🌟 Apni Admin Dashboard screen ka import yahan un-comment kar lein

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  // 🚀 ADMIN LOGIN LOGIC (Ab purely 'admins' collection ke sath)
  Future<void> _handleAdminLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Firebase Auth se login check karo (Admin ka email aur password)
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null && mounted) {
          // 2. 🔥 REWRITE: Ab data normal users mein nahi, 'admins' collection mein dhooda jayega
          DocumentSnapshot adminDoc = await FirebaseFirestore.instance
              .collection('admins') // 👈 Purely 'admins' collection ko target kiya
              .doc(user.uid)
              .get();

          String role = '';

          if (adminDoc.exists) {
            Map<String, dynamic> adminData = adminDoc.data() as Map<String, dynamic>;
            role = (adminData['role'] ?? '').toString().toLowerCase().trim();
          }

          // 3. STRICT CHECK: Kya yeh banda 'admins' collection ka admin hai?
          if (role == 'admin') {
            // ✅ Agar admin hai toh seedha Admin Dashboard par bhej do
            if (mounted) {
              _showSnackBar("Admin Login Successful!", isError: false);

              // Navigator.pushAndRemoveUntil(
              //   context,
              //   MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              //       (route) => false,
              // );
            }
          } else {
            // ❌ Agar role admin nahi hai ya record galat hai, toh Sign Out karo
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showSnackBar("Access Denied: You are not an Admin!", isError: true);
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = "Authentication failed";
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          message = "Account not found or invalid credentials.";
        } else if (e.code == 'wrong-password') {
          message = "Incorrect password. Please try again.";
        }
        _showSnackBar(message, isError: true);
      } catch (e) {
        _showSnackBar("Error: ${e.toString()}", isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  // 🌟 MEMORY SAFETY: Controllers ko destroy karna zaroori hai
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F1A), // Admin ke liye premium dark green theme
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Digital Islamic Hub",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Admin Control Panel",
                  style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 1.5),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                          "Admin Login",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Admin Email",
                          labelStyle: TextStyle(color: Colors.white60),
                          prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                        ),
                        validator: (val) => (val == null || !val.contains("@")) ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                        validator: (val) => (val == null || val.isEmpty) ? "Password is required" : null,
                      ),
                      const SizedBox(height: 40),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Login as Admin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}