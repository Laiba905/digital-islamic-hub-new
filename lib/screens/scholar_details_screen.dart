import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import 'scholar_dashboard.dart';

class ScholarDetailsScreen extends StatefulWidget {
  const ScholarDetailsScreen({super.key});

  @override
  State<ScholarDetailsScreen> createState() => _ScholarDetailsScreenState();
}

class _ScholarDetailsScreenState extends State<ScholarDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _expertiseController = TextEditingController();

  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploading = false;

  final String _cloudName = "lxuuhill";
  final String _uploadPreset = "AppPresent";

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await _uploadToCloudinary(bytes, pickedFile.name);
      } else {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: AppTheme.primaryLight,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          await _uploadToCloudinary(bytes, croppedFile.path.split('/').last);
        }
      }
    }
  }

  Future<void> _uploadToCloudinary(Uint8List imageBytes, String fileName) async {
    setState(() => _isUploading = true);
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        setState(() => _imageUrl = jsonData['secure_url']);
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload your profile image.")));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('scholars').doc(user!.uid).update({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'expertise': _expertiseController.text.trim(),
        'profileImage': _imageUrl,
        'profileCompleted': true,
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ScholarDashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Scholar Registration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndCropImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? Icon(Icons.add_a_photo, size: 30, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Upload Professional Photo", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                  const SizedBox(height: 30),
                  _buildField(_phoneController, "Contact Number", Icons.phone, TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildField(_expertiseController, "Expertise (e.g. Fiqh, Hadith)", Icons.star_border, TextInputType.text),
                  const SizedBox(height: 20),
                  _buildField(_addressController, "Location / City", Icons.location_on_outlined, TextInputType.text),
                  const SizedBox(height: 20),
                  _buildField(_bioController, "Short Bio", Icons.info_outline, TextInputType.multiline, maxLines: 3),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_isLoading || _isUploading) ? null : _saveDetails,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("Submit Application", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildField(TextEditingController ctrl, String lbl, IconData icon, TextInputType type, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: lbl,
        prefixIcon: Icon(icon, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? "This field is required" : null,
    );
  }
}
