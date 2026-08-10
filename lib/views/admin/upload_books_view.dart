import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class UploadBooksView extends StatefulWidget {
  const UploadBooksView({super.key});

  @override
  State<UploadBooksView> createState() => _UploadBooksViewState();
}

class _UploadBooksViewState extends State<UploadBooksView> {
  bool _isUploading = false;

  Future<void> _openPDF(BuildContext context, String pdfUrl) async {
    final Uri uri = Uri.parse(pdfUrl);
    try {
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF. Error: $e')),
        );
      }
    }
  }

  // 📂 Nayi Book Upload karne ka Corrected Function
  Future<void> _showUploadDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    PlatformFile? pickedFile;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Upload New Islamic Book'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Book Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(labelText: 'Author Name'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                          withData: true,
                        );
                        if (result != null) {
                          setDialogState(() {
                            pickedFile = result.files.first;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(pickedFile == null ? 'Select PDF File' : 'Selected: ${pickedFile!.name}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleController.text.isEmpty || authorController.text.isEmpty || pickedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields and select a PDF!')),
                      );
                      return;
                    }

                    // Pehle dialog band karein taake UI free ho jaye
                    Navigator.pop(dialogContext);

                    setState(() { _isUploading = true; });

                    try {
                      const cloudName = 'lxuuhill';
                      const uploadPreset = 'unsigned_preset';

                      Uint8List? fileBytes = pickedFile!.bytes;
                      if (fileBytes == null) {
                        throw Exception('File bytes are empty!');
                      }

                      // auto/upload use karna ziada behtar hai taake file type ka masla na ho
                      var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');

                      var request = http.MultipartRequest('POST', uri)
                        ..fields['upload_preset'] = uploadPreset
                        ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: pickedFile!.name));

                      var streamedResponse = await request.send();
                      var response = await http.Response.fromStream(streamedResponse);

                      if (response.statusCode == 200) {
                        var jsonData = json.decode(response.body);
                        String downloadUrl = jsonData['secure_url'];

                        // 📌 Save to Firestore (Manage Library / uploaded_books)
                        await FirebaseFirestore.instance.collection('uploaded_books').add({
                          'title': titleController.text.trim(),
                          'author': authorController.text.trim(),
                          'pdfUrl': downloadUrl,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book uploaded successfully!')),
                          );
                        }
                      } else {
                        throw Exception('Cloudinary Error: ${response.body}');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() { _isUploading = false; });
                      }
                    }
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Islamic Books Library'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('uploaded_books').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Something went wrong: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No books available right now. Click + to add one.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final books = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index].data() as Map<String, dynamic>;
                  final String title = book['title'] ?? 'No Title';
                  final String author = book['author'] ?? 'Unknown Author';
                  final String pdfUrl = book['pdfUrl'] ?? '';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF004D40),
                        child: Icon(Icons.menu_book, color: Colors.white),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Author: $author', style: const TextStyle(color: Colors.grey)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () {
                          if (pdfUrl.isNotEmpty) {
                            _openPDF(context, pdfUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF link is invalid!')),
                            );
                          }
                        },
                        tooltip: 'Read PDF',
                      ),
                      onTap: () {
                        if (pdfUrl.isNotEmpty) {
                          _openPDF(context, pdfUrl);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Uploading Book, Please wait...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        onPressed: () => _showUploadDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}