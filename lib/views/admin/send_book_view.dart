import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class SendBookView extends StatefulWidget {
  const SendBookView({super.key});

  @override
  State<SendBookView> createState() => _SendBookViewState();
}

class _SendBookViewState extends State<SendBookView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isLoading = false;
  String _uploadStatus = '';

  final String cloudinaryCloudName = "lxuuhill";
  final String cloudinaryUploadPreset = "AppPresent";

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickBookFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'zip'],
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking file: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_pickedFile == null) return null;

    try {
      setState(() => _uploadStatus = 'Uploading to Cloudinary...');

      String url = "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/auto/upload";
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['upload_preset'] = cloudinaryUploadPreset;

      if (kIsWeb) {
        if (_pickedFile!.bytes == null) return null;
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        ));
      } else {
        if (_pickedFile!.path == null) return null;
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _pickedFile!.path!,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['secure_url'];
      } else {
        print("Cloudinary Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Upload Exception: $e");
      return null;
    }
  }

  Future<void> _sendBookToUsers() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields properly."), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an Islamic book PDF file!"), backgroundColor: Colors.orange),
      );
      return;
    }

    final String titleText = _titleController.text.trim();
    final String authorText = _authorController.text.trim();
    final String fileNameText = _pickedFile!.name;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Processing...';
    });

    String? pdfUrl = await _uploadToCloudinary();

    if (pdfUrl != null) {
      try {
        setState(() => _uploadStatus = 'Saving to database...');

        await FirebaseFirestore.instance.collection('uploaded_books').add({
          'title': titleText,
          'author': authorText,
          'pdfUrl': pdfUrl,
          'fileName': fileNameText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Islamic Book sent successfully to users!"), backgroundColor: Colors.green),
          );

          _titleController.clear();
          _authorController.clear();
          setState(() {
            _pickedFile = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Firestore Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload book to Cloudinary."), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _uploadStatus = '';
      });
    }
  }

  // 🚀 User app wala tested open function
  Future<void> _openBookUrl(BuildContext context, String fileUrl, String title) async {
    final Uri url = Uri.parse(fileUrl.trim());
    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!launched) {
        launched = await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the book URL.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteBook(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('uploaded_books').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Book deleted successfully."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send & Manage Islamic Books'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Upload Form Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Upload New Islamic Book',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Book Title (e.g., Riyad-us-Saliheen)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter book title' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: 'Author Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter author name' : null,
                          ),
                          const SizedBox(height: 24),

                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pickBookFile,
                            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF004D40)),
                            label: Text(
                              _pickedFile == null ? 'Select Islamic Book (PDF)' : 'Selected: ${_pickedFile!.name}',
                              style: const TextStyle(color: Color(0xFF004D40)),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF004D40)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_isLoading) ...[
                            Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(color: Color(0xFF004D40)),
                                  const SizedBox(height: 12),
                                  Text(_uploadStatus, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isLoading ? null : _sendBookToUsers,
                              child: const Text('Send Book to Users', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                const Divider(thickness: 2),
                const SizedBox(height: 20),

                // 2. Previously Sent Books List
                const Text(
                  'Previously Sent Books (Admin History)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                ),
                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('uploaded_books').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No books sent yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      );
                    }

                    final sentBooks = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sentBooks.length,
                      itemBuilder: (context, index) {
                        final doc = sentBooks[index];
                        final bookData = doc.data() as Map<String, dynamic>;
                        final title = bookData['title'] ?? 'No Title';
                        final author = bookData['author'] ?? 'Unknown';
                        final fileName = bookData['fileName'] ?? '';
                        final pdfUrl = bookData['pdfUrl'] ?? '';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF004D40),
                              child: Icon(Icons.menu_book, color: Colors.white),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Author: $author\nFile: $fileName'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF004D40)),
                                  tooltip: 'View Book',
                                  onPressed: () {
                                    if (pdfUrl.isNotEmpty) {
                                      _openBookUrl(context, pdfUrl, title);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Book',
                                  onPressed: () {
                                    _deleteBook(doc.id);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              if (pdfUrl.isNotEmpty) {
                                _openBookUrl(context, pdfUrl, title);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}