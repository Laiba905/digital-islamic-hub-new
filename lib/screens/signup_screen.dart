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

  // Strict Email Validator Function
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Step-by-Step Strict Password Validator (Alphabet -> Number -> Symbol pattern)
  String? _validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters long";
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return "Please enter alphabets/letters first (e.g. Abc)";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Then enter numbers (e.g. 123)";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Finally enter a special symbol (e.g. @#!)";
    }
    return null;
  }

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
          // 1. Create new account
          userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          User? user = userCredential.user;

          // 2. Send email verification link (Sirf User ke liye ya dono ke liye bhej dein)
          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            try {
              userCredential = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(email: email, password: password);
            } catch (signInError) {
              throw Exception("This email is already registered. Please enter the correct password.");
            }
          } else {
            rethrow;
          }
        }

        User? currentUser = userCredential?.user;
        if (currentUser == null) {
          throw Exception("Authentication failed.");
        }

        // 3. Reload current user info
        await currentUser.reload();
        currentUser = FirebaseAuth.instance.currentUser;

        // --- YAHAN MAIN CHANGE HAI ---
        // Agar role 'user' hai, toh email verification check hogi.
        // Agar role 'scholar' hai, toh verification check BYPASS kar di hai taake aap foran aage ja sakein!
        if (finalRole == 'user') {
          if (!currentUser!.emailVerified) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() => _isLoading = false);
              _showVerificationNoticeDialog(email);
            }
            return;
          }
        }
        // -----------------------------

        String uid = currentUser!.uid;

        // 4. Handle Role-based Database Entry & Flow
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
              if (mounted) _showPendingPopup(context);
            } else if (status == 'approved') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Welcome back, Scholar!"), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              }
            }
          } else {
            // Create initial scholar doc if not exists
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
          // Standard User Flow
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
              const SnackBar(content: Text("Account successfully created and verified!"), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = e.code == 'wrong-password' ? "Incorrect password." : "Authentication failed: ${e.message}";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationNoticeDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread, color: Colors.green),
            SizedBox(width: 8),
            Text("Verify Your Email"),
          ],
        ),
        content: Text(
          "A verification link has been sent to your email ($email). Please check your Inbox or Spam folder, verify your account via the link, and then log in.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryLight, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK, Got it"),
          ),
        ],
      ),
    );
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
          "Your application has been submitted. You will get access to the dashboard within a few hours.   ",
          style: TextStyle(fontSize: 14),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildHeaderTitle(isDark)),
                  const SizedBox(height: 25),

                  _buildRoleSelectorContainer(isDark),
                  const SizedBox(height: 25),

                  _buildReusableTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    isDark: isDark,
                    validator: (v) => v!.isEmpty ? "Enter name" : null,
                  ),
                  const SizedBox(height: 20),

                  _buildReusableTextField(
                    controller: _emailController,
                    label: "Email (Valid email required)",
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Email is required";
                      }
                      if (!_isValidEmail(v.trim())) {
                        return "Please enter a valid email address (e.g., user@gmail.com)";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildReusableTextField(
                    controller: _passwordController,
                    label: "Password (Min 6 chars)",
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: _validateStrongPassword,
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "• Password must be at least 6 characters.\n• Pattern requirement:\n   1. Enter alphabets/letters first (e.g. Abc)\n   2. Then enter numbers (e.g. 123)\n   3. Finally enter a special symbol (e.g. @#!)",
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildSubmitButton(isDark),
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
      "Create Account",
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppTheme.primaryLight,
      ),
    );
  }

  Widget _buildRoleSelectorContainer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildRoleTab('user', isDark),
          _buildRoleTab('scholar', isDark),
        ],
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? AppTheme.primaryDark : Colors.white)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
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
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
          foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}