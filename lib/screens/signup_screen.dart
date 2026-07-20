import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scholar_details_screen.dart';
// import 'user_home_screen.dart'; // 🌟 Apni user home screen ka import yahan un-comment kar lein

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

  // Role selection state tracker ('user' ya 'scholar')
  String _selectedRole = 'user';

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 🌟 STATE SAFETY LOCK: Variables ko local local constants mein store kar liya taake rebuild se reset na hon
      final String finalRole = _selectedRole.toLowerCase().trim();
      final String email = _emailController.text.trim();
      final String name = _nameController.text.trim();
      final String password = _passwordController.text.trim();

      // 🚀 DEBUG PRINTS: Console mein check karne ke liye ke data kis raste par ja raha hai
      print("--------------------------------------------------");
      print("🚀 SIGN UP TRIGGERED!");
      print("📧 Target Email: $email");
      print("🎯 Captured Role: $finalRole");
      print("--------------------------------------------------");

      try {
        // 1. Create User in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String uid = userCredential.user!.uid;

        // 2. Separate Collections Logic based on Selected Role
        if (finalRole == 'scholar') {
          print("🔥 WRITING: Pushing data to 'scholars' collection for UID: $uid");

          Map<String, dynamic> scholarData = {
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'scholar',
            'isVerifiedScholar': false,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('scholars') // 👈 Purely 'scholars' collection
              .doc(uid)
              .set(scholarData);

        } else {
          print("📱 WRITING: Pushing data to 'users' collection for UID: $uid");

          Map<String, dynamic> userData = {
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'User',
            'status': 'active',
            'current_streak': 0,
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('users') // 👈 Purely 'users' collection
              .doc(uid)
              .set(userData);
        }

        // 3. Move to screens based on selected role
        if (mounted) {
          if (finalRole == 'scholar') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ScholarDetailsScreen()),
                  (route) => false,
            );
          } else {
            // User ke liye direct dashboard/homescreen link
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   MaterialPageRoute(builder: (context) => const UserHomeScreen()),
            //       (route) => false,
            // );
          }
        }
      } on FirebaseAuthException catch (e) {
        print("❌ FIREBASE AUTH ERROR: ${e.code}");
        String message = "Sign up failed";
        if (e.code == 'email-already-in-use') {
          message = "This email is already registered.";
        } else if (e.code == 'weak-password') {
          message = "Password is too weak.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red));
      } catch (e) {
        print("❌ SYSTEM ERROR: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 RESPONSIVENESS: Fetch real screen width for Web, Android, iOS
    final double screenWidth = MediaQuery.of(context).size.width;

    // Standard Breakpoint: Agar screen width 600px se bari hai toh desktop/web layout apply hoga
    bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Premium light green
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            // Web/iPad par card width 450px par lock ho jayegi, mobile par complete responsive screen stretch hogi
            width: isWeb ? 450 : double.infinity,
            padding: EdgeInsets.all(isWeb ? 40 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
                  ),
                  const SizedBox(height: 25),

                  // ROLE SELECTOR BUTTONS (User vs Scholar)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // User Selection Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = 'user'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'user' ? const Color(0xFF2E7D32) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "User",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'user' ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Scholar Selection Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = 'scholar'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'scholar' ? const Color(0xFF2E7D32) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Scholar",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'scholar' ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? "Enter name" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || !val.contains("@")) ? "Enter valid email" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.length < 6) ? "Min 6 chars" : null,
                  ),
                  const SizedBox(height: 35),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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