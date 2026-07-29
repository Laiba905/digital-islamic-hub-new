import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scholar_details_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'user';

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String finalRole = _selectedRole.toLowerCase().trim();
      final String email = _emailController.text.trim();
      final String name = _nameController.text.trim();
      final String password = _passwordController.text.trim();

      try {
        // 1. Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;

        // 2. Database Write
        if (finalRole == 'scholar') {
          // --- SCHOLAR BLOCK ---
          await FirebaseFirestore.instance.collection('scholars').doc(uid).set({
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'scholar',
            'isVerifiedScholar': false,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ScholarDetailsScreen()),
            );
          }
        } else {
          // --- USER BLOCK (Sirf Name, Email aur Role) ---
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'User',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Agar aapko HomeScreen ya kahin aur bhejna ho toh yahan Navigator add kar sakte hain
        }
      } on FirebaseAuthException catch (e) {
        String message = e.code == 'email-already-in-use' ? "Email already exists." : "Sign up failed.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isWeb ? 450 : double.infinity,
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 25),

                  // Role Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildRoleTab('user'),
                        _buildRoleTab('scholar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Enter name" : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()), validator: (v) => !v!.contains("@") ? "Invalid email" : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), validator: (v) => v!.length < 6 ? "Min 6 chars" : null),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up"),
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

  Widget _buildRoleTab(String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(role.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black54))),
        ),
      ),
    );
  }
}