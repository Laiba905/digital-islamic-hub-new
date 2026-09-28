import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/view_models/profile_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 🔑 Yahan aap apni marzi ki email aur password hardcode kar sakti hain
  final String _hardcodedAdminEmail = "malaikatariq0102@gmail.com";
  final String _hardcodedAdminPassword = "223344"; // Apna password yahan set kar lein

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hardcoded Admin Login Logic
  Future<void> _handleAdminLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Thoda sa delay taake loading feel ho
      await Future.delayed(const Duration(milliseconds: 500));

      String enteredEmail = _emailController.text.trim();
      String enteredPassword = _passwordController.text.trim();

      // Check karein ke email aur password match hote hain ya nahi
      if (enteredEmail == _hardcodedAdminEmail && enteredPassword == _hardcodedAdminPassword) {

        // Safe name extraction from email
        if (enteredEmail.contains('@')) {
          String name = enteredEmail.split('@')[0];
          if (name.isNotEmpty) {
            if (mounted) {
              Provider.of<ProfileViewModel>(context, listen: false).updateName(name);
            }
          }
        }

        // Dashboard par bhej dein
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // Agar ghalat email ya password enter kiya ho
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid email or password."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF001A12), const Color(0xFF002419)]
              : [const Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth < 600 ? 24 : 40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Admin Portal',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF004D40),
                          ),
                        ),
                        const Text(
                          'Please sign in to continue',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) => value!.isEmpty ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) => value!.isEmpty ? 'Enter password' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAdminLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Color(0xFF002419))
                                : const Text('LOGIN', style: TextStyle(fontSize: 16, letterSpacing: 1.2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
