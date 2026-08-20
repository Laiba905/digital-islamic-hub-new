import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';

class UserBookListView extends StatefulWidget {
  const UserBookListView({super.key});

  @override
  State<UserBookListView> createState() => _UserBookListViewState();
}

class _UserBookListViewState extends State<UserBookListView> {
  final Map<String, double> _downloadProgress = {};

  // File check function for mobile/web
  Future<bool> _checkLocalFile(String path) async {
    if (kIsWeb) {
      return false;
    } else {
      return await io.File(path).exists();
    }
  }

  Future<void> _downloadAndOpenPDF(BuildContext context, String fileUrl, String title) async {
    // 1. Web ke liye: Naye tab mein safe tarike se kholna
    if (kIsWeb) {
      final Uri url = Uri.parse(fileUrl);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, webOnlyWindowName: '_blank');
        } else {
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
      return;
    }

    // 2. Mobile ke liye: Local storage mein smooth download aur offline view
    try {
      var directory = await getApplicationDocumentsDirectory();
      String safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      String savePath = '${directory.path}/$safeTitle.pdf';

      bool fileExists = await _checkLocalFile(savePath);

      if (fileExists) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(localPath: savePath, title: title),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading "$title" for offline use...')),
        );
      }

      Dio dio = Dio();
      await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;

            // 🚀 Hang hone se bachane ke liye optimized logic (UI bar bar refresh nahi hogi)
            if ((_downloadProgress[fileUrl] ?? 0) + 0.05 <= progress || progress == 1.0) {
              if (mounted) {
                setState(() {
                  _downloadProgress[fileUrl] = progress;
                });
              }
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(fileUrl);
        });
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(localPath: savePath, title: title),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(fileUrl);
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('uploaded_books').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No books available.'));
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

              double? progress = _downloadProgress[pdfUrl];
              bool isDownloading = progress != null;

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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Author: $author', style: const TextStyle(color: Colors.grey)),
                  ),
                  trailing: isDownloading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: const Color(0xFF004D40),
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      kIsWeb ? Icons.visibility : Icons.download_rounded,
                      color: const Color(0xFF004D40),
                      size: 26,
                    ),
                    onPressed: () => _downloadAndOpenPDF(context, pdfUrl, title),
                    tooltip: kIsWeb ? 'View Book' : 'Download & Read',
                  ),
                  onTap: () {
                    if (pdfUrl.isNotEmpty && !isDownloading) {
                      _downloadAndOpenPDF(context, pdfUrl, title);
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