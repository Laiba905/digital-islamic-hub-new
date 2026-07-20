import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
// Apni file ka path sahi se import karein
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

  // Purana cloudinary variable yahan se hata diya gaya hai

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

  // UPDATED: Ab hum CloudinaryService use kar rahe hain
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload image")));
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitted Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... (Baaki ka Build method aur CustomInputField waisa hi rahega)
  @override
  Widget build(BuildContext context) {
    // ... (Aapka existing build code yahan aayega)
    return Scaffold( /* ... */ );
  }
}