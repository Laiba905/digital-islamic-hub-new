import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/view_models/profile_view_model.dart';
import 'package:admin/view_models/theme_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
    _nameController = TextEditingController(text: profileVM.adminName);

    // Listen to changes so controller updates if data fetches late from Firestore
    profileVM.addListener(_updateNameController);
  }

  void _updateNameController() {
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
    if (_nameController.text != profileVM.adminName) {
      _nameController.text = profileVM.adminName;
    }
  }

  @override
  void dispose() {
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
    profileVM.removeListener(_updateNameController);
    _nameController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog(ProfileViewModel profileVM) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF004D40)),
              title: const Text('Pick Image'),
              onTap: () {
                Navigator.pop(context);
                profileVM.pickAndUploadProfileImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<ProfileViewModel>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Profile Picture Section
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xFF004D40),
                      backgroundImage: profileVM.profileImageUrl != null && profileVM.profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileVM.profileImageUrl!)
                          : null,
                      child: profileVM.isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : (profileVM.profileImageUrl == null || profileVM.profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                    FloatingActionButton.small(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      onPressed: profileVM.isUploading ? null : () => _showImageSourceDialog(profileVM),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Name Change Section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              profileVM.updateName(_nameController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name Updated successfully!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004D40),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Update Name'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section (Dark Mode)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Change the appearance of the dashboard'),
                          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                          value: isDark,
                          onChanged: (val) {
                            themeProvider.toggleTheme(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}