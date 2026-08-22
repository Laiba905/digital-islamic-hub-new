import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
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
  bool _obscurePassword = true;
  String _selectedRole = 'user';

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String finalRole = _selectedRole.toLowerCase().trim();
      final String email = _emailController.text.trim();
      final String name = _nameController.text.trim();
      final String password = _passwordController.text.trim();

      try {
        UserCredential? userCredential;

        try {
          userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
          } else {
            rethrow;
          }
        }

        String uid = userCredential!.user!.uid;

        if (finalRole == 'scholar') {
          DocumentSnapshot scholarDoc = await FirebaseFirestore.instance
              .collection('scholars')
              .doc(uid)
              .get();

          if (scholarDoc.exists) {
            Map<String, dynamic> data = scholarDoc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            bool isDetailsFilled = data.containsKey('phone') && data.containsKey('image');

            if (!isDetailsFilled) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ScholarDetailsScreen()),
                );
              }
            } else if (status == 'pending') {
              if (mounted) {
                _showPendingPopup(context);
              }
            } else if (status == 'approved') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Welcome back, Scholar!"), backgroundColor: Colors.green),
              );
            }
          } else {
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
          }
        } else {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'User',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = e.code == 'wrong-password' ? "Incorrect password for this email." : "Authentication failed: ${e.message}";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showPendingPopup(BuildContext context) {
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
            "Your application is currently pending. You will be able to access the dashboard once verification is completed by the admin.",          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryLight, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : const Color(0xFFE8F5E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isWeb ? 450 : double.infinity,
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(15) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryLight)),
                  const SizedBox(height: 25),

                  // Role Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildRoleTab('user', isDark),
                        _buildRoleTab('scholar', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Full Name", 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? "Enter name" : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Email", 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: isDark ? Colors.white60 : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                  ),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, 
                        foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text(" Continue"),
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

  Widget _buildRoleTab(String role, bool isDark) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppTheme.accentGreen : AppTheme.primaryLight) : Colors.transparent, 
            borderRadius: BorderRadius.circular(10)
          ),
          child: Center(
            child: Text(
              role.toUpperCase(), 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected 
                  ? (isDark ? AppTheme.primaryDark : Colors.white) 
                  : (isDark ? Colors.white60 : Colors.black54)
              )
            )
          ),
        ),
      ),
    );
  }
}