import 'package:flutter/material.dart';
import 'package:digital_islamic_hub_new/screens/scholar_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'scholar_details_screen.dart';

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
          // 1. Pehle check karein ke yeh scholar hai ya nahi
          DocumentSnapshot scholarDoc = await FirebaseFirestore.instance
              .collection('scholars')
              .doc(user.uid)
              .get();

          if (scholarDoc.exists) {
            Map<String, dynamic> scholarData = scholarDoc.data() as Map<String, dynamic>;
            String status = (scholarData['status'] ?? 'pending').toString().toLowerCase().trim();

            // Agar status APPROVED hai, toh chahe profileCompleted false bhi ho, seedha dashboard bhejein!
            if (status == 'approved') {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ScholarDashboard()),
                      (route) => false,
                );
              }
              return;
            }
            // Agar status REJECTED hai
            else if (status == 'rejected') {
              _showSnackBar("Your scholar verification request has been rejected.", isError: true);
              await FirebaseAuth.instance.signOut();
              return;
            }

            // Agar status PENDING ya approved nahi hai, tab check karein ke profile complete hai ya nahi
            bool hasPhoneAndImage = scholarData.containsKey('phone') && scholarData.containsKey('image');
            bool profileCompleted = scholarData['profileCompleted'] ?? hasPhoneAndImage;

            // Agar profile half-filled hai (adhoori chhodi thi) aur status approved nahi hai
            if (!profileCompleted) {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ScholarDetailsScreen()),
                      (route) => false,
                );
              }
              return;
            }

            // Agar status PENDING hai -> Popup show ho aur dashboard par na jaye
            if (mounted) {
              _showPendingPopup();
            }
            return;
          }

          // 2. Agar scholar nahi hai, tab aam user ('users' collection) wala code chalega
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            }
            return;
          }

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
          "Your application is currently pending. ",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            child: const Text("OK"),
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
        backgroundColor: isError ? Colors.redAccent : AppTheme.primaryLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.primaryLight, AppTheme.primaryDark]
                : [const Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeaderTitle(isDark),
                  const SizedBox(height: 40),
                  _buildFormContainer(isDark, context),
                  const SizedBox(height: 30),
                  _buildSignUpFooter(isDark, context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(bool isDark) {
    return Text(
      "Digital Islamic Hub",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppTheme.primaryLight,
      ),
    );
  }

  Widget _buildFormContainer(bool isDark, BuildContext context) {
    return Container(
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          _buildReusableTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
            isDark: isDark,
            validator: (val) => (val == null || !val.contains("@")) ? "Enter a valid email" : null,
          ),
          const SizedBox(height: 20),
          _buildReusableTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_outline,
            isDark: isDark,
            obscureText: _obscureText,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
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
                  color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
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
                backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
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
    );
  }

  Widget _buildReusableTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)),
      ),
      validator: validator,
    );
  }

  Widget _buildSignUpFooter(bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          children: [
            TextSpan(
              text: "Sign Up",
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
            ),
          ],
        ),
      ),
    );
  }
}