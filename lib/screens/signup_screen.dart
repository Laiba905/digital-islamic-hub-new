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
          // 1. Pehle Sign Up karne ki koshish karein
          userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
        } on FirebaseAuthException catch (e) {
          // 💡 Agar email pehle se mojood hai, toh hum automatically LOGIN karwa denge!
          if (e.code == 'email-already-in-use') {
            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
          } else {
            rethrow;
          }
        }

        String uid = userCredential!.user!.uid;

        if (finalRole == 'scholar') {
          // 2. Check karein ke kya scholar ki details pehle se Firestore mein hain?
          DocumentSnapshot scholarDoc = await FirebaseFirestore.instance
              .collection('scholars')
              .doc(uid)
              .get();

          if (scholarDoc.exists) {
            Map<String, dynamic> data = scholarDoc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            bool isDetailsFilled = data.containsKey('phone') && data.containsKey('image'); // Check ke details bhari hain ya nahi

            if (!isDetailsFilled) {
              // Agar details adhoori hain toh wapas ScholarDetailsScreen par bhejein
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ScholarDetailsScreen()),
                );
              }
            } else if (status == 'pending') {
              // Agar details bhari hain par admin ne approve nahi kiya, toh Popup dikhayein
              if (mounted) {
                _showPendingPopup(context);
              }
            } else if (status == 'approved') {
              // Agar approved hai toh scholar dashboard par bhej sakte hain (Aap apne dashboard ki screen ka naam yahan likh dein)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Welcome back, Scholar!"), backgroundColor: Colors.green),
              );
            }
          } else {
            // Agar scholar doc nahi bani toh nayi entry banayein aur details screen par bhejein
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
          // --- USER BLOCK ---
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'displayName': name,
            'email': email,
            'role': 'User',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
          );
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

  // 🕒 Pending Status Popup Dialog
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
          "Aap ki application abhi pending mein hai. Admin ki taraf se verification mukammal hone ke baad hi aap dashboard access kar sakenge.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut(); // Logout kar dein taake unauthorized access na ho
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
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

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Enter name" : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                    validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Field with Eye Icon
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
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
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up / Continue"),
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