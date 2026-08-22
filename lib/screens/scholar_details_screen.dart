import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'cloudinary_service.dart';
import '../theme/app_theme.dart';

class ScholarDetailsScreen extends StatefulWidget {
  const ScholarDetailsScreen({super.key});

  @override
  State<ScholarDetailsScreen> createState() => _ScholarDetailsScreenState();
}

class _ScholarDetailsScreenState extends State<ScholarDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _degreeController = TextEditingController();

  String? _selectedGender;
  String? _selectedPaymentMethod;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _paymentOptions = ['EasyPaisa', 'JazzCash', 'Both'];

  XFile? _pickedImageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;

  Future<void> _pickSanadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        setState(() { _webImageBytes = bytes; _pickedImageFile = image; });
      } else {
        setState(() { _pickedImageFile = image; });
      }
    }
  }

  Future<String?> _uploadToCloudinary(String userId) async {
    if (_pickedImageFile == null) return null;
    try {
      CloudinaryResponse response;
      if (kIsWeb) {
        response = await CloudinaryService.cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
              _webImageBytes!,
              resourceType: CloudinaryResourceType.Image,
              identifier: 'degree_image_$userId'
          ),
        );
      } else {
        response = await CloudinaryService.cloudinary.uploadFile(
            CloudinaryFile.fromFile(_pickedImageFile!.path, resourceType: CloudinaryResourceType.Image)
        );
      }
      return response.secureUrl;
    } catch (e) {
      debugPrint("Cloudinary Error: $e");
      return null;
    }
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Gender and Payment Method")));
      return;
    }
    if (_pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload certificate")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? imageUrl = await _uploadToCloudinary(user.uid);

      await FirebaseFirestore.instance.collection('scholars').doc(user.uid).set({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'degree': _degreeController.text.trim(),
        'gender': _selectedGender,
        'payment_method': _selectedPaymentMethod,
        'image': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final notificationData = {
        'targetRole': 'admin',
        'title': 'Scholar Verification Request',
        'message': 'New scholar (${user.email ?? 'Scholar'}) has requested verification.',
        'userName': user.email ?? 'Scholar',
        'amountPaid': '0',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('notifications').add(notificationData);
      await FirebaseFirestore.instance.collection('admin_notifications').add(notificationData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Sent Successfully!"), backgroundColor: AppTheme.primaryLight),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error Details"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Scholar Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Phone Number', 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    dropdownColor: isDark ? AppTheme.primaryDark : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Accept Payments via', 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    items: _paymentOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Address', 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? "Enter address" : null,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    dropdownColor: isDark ? AppTheme.primaryDark : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Gender', 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _degreeController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Degree / Qualification', 
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? "Enter degree" : null,
                  ),
                  const SizedBox(height: 25),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Please upload certificate",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: _pickSanadImage,
                          child: Container(
                            height: 180,
                            width: 320,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(10) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400),
                            ),
                            child: _pickedImageFile == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: isDark ? Colors.white30 : Colors.grey),
                                const SizedBox(height: 8),
                                Text("Tap to select certificate", style: TextStyle(color: isDark ? Colors.white30 : Colors.grey))
                              ],
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                  : Image.file(File(_pickedImageFile!.path), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                        foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Submit Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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