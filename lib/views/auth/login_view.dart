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
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Login',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _handleAdminLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}