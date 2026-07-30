import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'cloudinary_service.dart';

class UserBookListView extends StatelessWidget {
  const UserBookListView({super.key});

  // PDF Open karne ka behtareen tareeqa with URL Cleaning
  Future<void> _openPDF(BuildContext context, String pdfUrl) async {
    String fixedUrl = pdfUrl.trim();

    // 🛠️ 1. Cloudinary Type Fix (/image/upload/ ya /raw/upload/ ko /auto/upload/ mein badalna)
    if (fixedUrl.contains('/image/upload/')) {
      fixedUrl = fixedUrl.replaceFirst('/image/upload/', '/auto/upload/');
    } else if (fixedUrl.contains('/raw/upload/')) {
      fixedUrl = fixedUrl.replaceFirst('/raw/upload/', '/auto/upload/');
    }

    // 🛠️ 2. Duplicate Extension Fix (Misformatted .pdf.pdf ko .pdf karna)
    if (fixedUrl.endsWith('.pdf.pdf')) {
      fixedUrl = fixedUrl.substring(0, fixedUrl.length - 4);
    }

    final Uri uri = Uri.parse(fixedUrl);
    try {
      // Web ya Mobile ke mutabiq link launch karna
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw 'Could not launch $fixedUrl';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF. Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Islamic Books'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('uploaded_books')
            .snapshots(),
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
                'No books available right now.',
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
    );
  }
}