import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme/app_theme.dart';
import '../main.dart'; // main.dart se themeNotifier import karne k liye
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _base64Image;
  bool _isDarkMode = false;
  bool _isNotificationEnabled = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _base64Image = data['profileImage'];
            _isDarkMode = data['darkMode'] ?? false;
            _isNotificationEnabled = data['notifications'] ?? true;
            _nameController.text = data['displayName'] ?? user?.displayName ?? "";

            // App load hotay hi theme set karein
            themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
          });
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
  }

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery, imageQuality: 40)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.camera, imageQuality: 40)),
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF1B5E20),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null) {
        File file = File(croppedFile.path);
        String base64String = base64Encode(await file.readAsBytes());

        await _firestore.collection('users').doc(user!.uid).set({
          'profileImage': base64String,
        }, SetOptions(merge: true));

        setState(() {
          _base64Image = base64String;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF003D33) : const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Account Info"),
                  _buildSettingsCard(isDark, [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: "Display Name",
                      subtitle: _nameController.text.isEmpty ? "Set your name" : _nameController.text,
                      isDark: isDark,
                      onTap: () => _showEditNameDialog(),
                    ),
                    _buildSettingsTile(
                      icon: Icons.email_outlined,
                      title: "Email Address",
                      subtitle: user?.email ?? "N/A",
                      isDark: isDark,
                    ),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Settings & Theme"),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: "Dark Mode",
                      value: _isDarkMode,
                      color: Colors.blueAccent,
                      isDark: isDark,
                      onChanged: (val) {
                        setState(() => _isDarkMode = val);
                        // DATABASE UPDATE
                        _firestore.collection('users').doc(user!.uid).update({'darkMode': val});
                        // LIVE THEME CHANGE
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.notifications_none_outlined,
                      title: "Prayer Notifications",
                      value: _isNotificationEnabled,
                      color: Colors.orangeAccent,
                      isDark: isDark,
                      onChanged: (val) {
                        setState(() => _isNotificationEnabled = val);
                        _firestore.collection('users').doc(user!.uid).update({'notifications': val});
                      },
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF003D33) : const Color(0xFF1B5E20),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  backgroundImage: (_base64Image != null && _base64Image!.isNotEmpty)
                      ? MemoryImage(base64Decode(_base64Image!))
                      : null,
                  child: (_base64Image == null || _base64Image!.isEmpty)
                      ? Icon(Icons.person, size: 50, color: Colors.green.shade800)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _pickAndCropImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _nameController.text,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Islamic Hub Member",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required bool isDark, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required Color color, required bool isDark, required Function(bool) onChanged}) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      value: value,
      activeColor: const Color(0xFF2E7D32),
      onChanged: onChanged,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade100)),
      ).onPressed(() async {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }, child: const Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Name"),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "Enter your name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(user!.uid).update({'displayName': _nameController.text});
              setState(() {});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

extension on ButtonStyle {
  Widget onPressed(VoidCallback action, {required Widget child}) => ElevatedButton(style: this, onPressed: action, child: child);
}