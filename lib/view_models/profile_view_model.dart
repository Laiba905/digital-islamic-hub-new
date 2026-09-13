import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin/view_models/theme_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  String _adminName = "Administrator";
  String? _profileImageUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  String get adminName => _adminName;
  String? get profileImageUrl => _profileImageUrl;
  bool get isUploading => _isUploading;
  bool get isLoading => _isLoading;

  final String cloudName = 'lxuuhill';
  final String uploadPreset = 'AppPresent';

  ProfileViewModel() {
    fetchAdminData();
  }

  // 📥 Firestore ki 'admin' collection se data fetch karna
  Future<void> fetchAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _isLoading = true;
        notifyListeners();

        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('admin').doc(user.uid).get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            _adminName = data['name'] ?? data['displayName'] ?? _adminName;
            _profileImageUrl = data['profileImage'] ?? data['photoUrl'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1. Admin Name Update karke Firestore mein save karna
  Future<void> updateName(String newName) async {
    try {
      _adminName = newName;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('admin').doc(user.uid).set({
          'name': newName,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating name in Firestore: $e');
    }
  }

  // 2. Profile Image Pick, Upload (Cloudinary) & Save to Firestore
  Future<void> pickAndUploadProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        String fileName = result.files.single.name;

        _isUploading = true;
        notifyListeners();

        final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

        var request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName,
            ),
          );

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          String secureUrl = jsonData['secure_url'];

          await updateProfileImageUrl(secureUrl);
        } else {
          debugPrint('Upload Failed: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Exception during upload: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // URL ko state aur 'admin' collection dono mein save karna
  Future<void> updateProfileImageUrl(String url) async {
    _profileImageUrl = url;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('admin').doc(user.uid).set({
          'profileImage': url,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving profile image URL to Firestore: $e');
    }
  }

  // 3. Logout Function
  void logout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // 4. Dark / Light Mode Toggle Function
  void toggleTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme(!themeProvider.isDarkMode);
    notifyListeners();
  }
}