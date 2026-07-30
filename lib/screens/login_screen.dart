import 'package:flutter/material.dart';
import 'package:digital_islamic_hub_new/screens/scholar_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null && mounted) {
          // 🔍 1. Pehle 'scholars' collection check karein
          DocumentSnapshot scholarDoc = await FirebaseFirestore.instance
              .collection('scholars')
              .doc(user.uid)
              .get();

          if (scholarDoc.exists) {
            Map<String, dynamic> scholarData = scholarDoc.data() as Map<String, dynamic>;
            String status = (scholarData['status'] ?? 'pending').toString().toLowerCase().trim();

            // Yeh check karein ke kya pehle popup dikhaya ja chuka hai ya nahi
            bool popupShown = scholarData['isApprovedPopupShown'] ?? false;

            if (status == 'approved') {
              if (popupShown) {
                // Agar popup pehle dikh chuka hai, toh seedha Scholar Dashboard par bhej dein
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ScholarDashboard()),
                        (route) => false,
                  );
                }
              } else {
                // Agar pehli baar approve hone ke baad login kiya hai, toh Congratulations Popup dikhayein
                if (mounted) {
                  _showApprovedPopup(user.uid);
                }
              }
              return;
            } else if (status == 'rejected') {
              // ❌ Agar request reject ho gayi hai
              _showSnackBar("Your scholar verification request has been rejected.", isError: true);
              await FirebaseAuth.instance.signOut();
              return;
            } else {
              // ⏳ Agar abhi 'pending' hai toh English Popup dikhayein aur login screen par hi rahein
              if (mounted) {
                _showPendingPopup();
              }
              return;
            }
          }

          // 🔍 2. Agar scholar nahi hai, toh 'users' collection check karein (Aam User ke liye)
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            // 👤 Regular User -> Seedha HomeScreen
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            }
            return;
          }

          // Agar kisi bhi collection mein record na mile
          _showSnackBar("User record not found in database.", isError: true);
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

  // 🕒 Pending Status Popup Dialog (English Version)
  void _showPendingPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.orange),
            SizedBox(width: 8),
            Text("Application Pending"),
          ],
        ),
        content: const Text(
          "Your application is currently pending. You will be able to access the dashboard once the admin completes the verification process.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close popup
              FirebaseAuth.instance.signOut(); // Stay on login screen securely
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 🎉 Approved Status Popup Dialog (Congratulations & Go to Dashboard)
  void _showApprovedPopup(String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00C853)),
            SizedBox(width: 8),
            Text("Congratulations! 🎉"),
          ],
        ),
        content: const Text(
          "Your application has been accepted. You can now access your dashboard.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Jaise hi user click kare, database mein update kardein ke popup dikhaya ja chuka hai
              await FirebaseFirestore.instance.collection('scholars').doc(uid).update({
                'isApprovedPopupShown': true,
              });

              if (context.mounted) {
                Navigator.pop(context); // Close popup
                // Navigate to Scholar Dashboard
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ScholarDashboard()),
                      (route) => false,
                );
              }
            },
            child: const Text("Go to Dashboard"),
          ),
        ],
      ),
    );
  }

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
                      boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
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