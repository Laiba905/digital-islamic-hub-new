import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

      String url = "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/raw/upload";
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendBookToUsers() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a book file first!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Starting process...';
    });

    try {
      String? bookUrl = await _uploadToCloudinary();

      if (bookUrl == null) {
        throw Exception("Failed to upload book to Cloudinary.");
      }

      setState(() => _uploadStatus = 'Saving to database...');

      String bookTitle = _titleController.text.trim();

      // 1️⃣ Save to 'uploaded_books' collection with 'pdfUrl'
      await FirebaseFirestore.instance.collection('uploaded_books').add({
        'title': bookTitle,
        'author': _authorController.text.trim(),
        'pdfUrl': bookUrl,
        'fileName': _pickedFile!.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Generate Notification for Users
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetRole': 'user',
        'title': 'New Book Added ', "A new book '$bookTitle' has been added, read it now!"
            'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear controllers and picked file after success
      _titleController.clear();
      _authorController.clear();
      setState(() {
        _pickedFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Book Shared  Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Share a Book"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth < 600 ? 20.0 : 40.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 60,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Share Book with Users",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: "Book Title",
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (v) => v!.isEmpty ? "Enter title" : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: "Author Name",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v!.isEmpty ? "Enter author" : null,
                          ),
                          const SizedBox(height: 32),

                          InkWell(
                            onTap: _isLoading ? null : _pickBookFile,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.file_present, color: isDark ? Colors.tealAccent : Colors.teal),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _pickedFile == null ? "Select Book File (PDF)" : _pickedFile!.name,
                                      style: TextStyle(
                                        color: _pickedFile == null ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_pickedFile != null)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ),

                          if (_isLoading) ...[
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(_uploadStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],

                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendBookToUsers,
                              child: const Text("SHARE BOOK NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 📚 Uploaded Books History Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Uploaded Books History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('uploaded_books')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      const Text("No books uploaded yet.", style: TextStyle(color: Colors.grey));
                    }
                    var books = snapshot.data?.docs ?? [];
                    if (books.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No upload history found.", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        var bookDoc = books[index];
                        var data = bookDoc.data() as Map<String, dynamic>;
                        String title = data['title'] ?? 'Untitled';
                        String author = data['author'] ?? 'Unknown';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.book, color: Colors.teal),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Author: $author"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Book"),
                                    content: Text("Are you sure you want to delete '$title'?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('uploaded_books')
                                        .doc(bookDoc.id)
                                        .delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Book deleted successfully!")),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error deleting book: $e")),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
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