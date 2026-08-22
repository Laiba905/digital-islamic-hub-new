import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'cloudinary_service.dart';

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
      print("Cloudinary Error: $e");
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

      // 1️⃣ Scholars collection mein details save karna
      await FirebaseFirestore.instance.collection('scholars').doc(user.uid).set({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'degree': _degreeController.text.trim(),
        'gender': _selectedGender,
        'payment_method': _selectedPaymentMethod,
        'image': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2️⃣ 🚀 Admin ke liye notifications aur admin_notifications donon mein entry bhej rahe hain
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

      print("SUCCESS: Notification sent successfully to Firestore!");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Sent Successfully!")),
      );
    } catch (e) {
      print("CRITICAL ERROR: $e");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scholar Verification"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  // 1. Phone Field
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  // 2. Payment Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(labelText: 'Accept Payments via', border: OutlineInputBorder()),
                    items: _paymentOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 20),

                  // 3. Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  // 4. Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 20),

                  // 5. Degree Field
                  TextFormField(
                    controller: _degreeController,
                    decoration: const InputDecoration(labelText: 'Degree / Qualification', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 25),

                  // 6. Please Upload Certificate Section
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Please upload certificate",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: _pickSanadImage,
                          child: Container(
                            height: 180,
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _pickedImageFile == null
                                ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("Tap to select certificate", style: TextStyle(color: Colors.grey))
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

                  // 7. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
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