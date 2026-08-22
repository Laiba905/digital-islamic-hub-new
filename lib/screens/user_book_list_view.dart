import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';
import '../theme/app_theme.dart';

class UserBookListView extends StatefulWidget {
  const UserBookListView({super.key});

  @override
  State<UserBookListView> createState() => _UserBookListViewState();
}

class _UserBookListViewState extends State<UserBookListView> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadedStatus = {}; // 🚀 Yeh track karega ke kaunsi book download ho chuki hai

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _checkLocalFile(String path) async {
    if (kIsWeb) {
      return false;
    } else {
      return await io.File(path).exists();
    }
  }

  // 🚀 Har book ka local path check karne ka function
  Future<void> _checkIfDownloaded(String title, String pdfUrl) async {
    if (kIsWeb) return;
    try {
      var directory = await getApplicationDocumentsDirectory();
      String safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      String savePath = '${directory.path}/$safeTitle.pdf';
      bool exists = await io.File(savePath).exists();
      if (mounted) {
        setState(() {
          _downloadedStatus[pdfUrl] = exists;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _downloadAndOpenPDF(BuildContext context, String fileUrl, String title) async {
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

    try {
      var directory = await getApplicationDocumentsDirectory();
      String safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      String savePath = '${directory.path}/$safeTitle.pdf';

      bool fileExists = await _checkLocalFile(savePath);

      if (fileExists) {
        if (mounted) {
          setState(() {
            _downloadedStatus[fileUrl] = true;
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
          _downloadedStatus[fileUrl] = true; // 🚀 Download complete hote hi status true kar diya
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Islamic Books Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('uploaded_books').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No books available.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)));
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

              // Check if file is already downloaded locally
              if (_downloadedStatus[pdfUrl] == null && !kIsWeb) {
                _checkIfDownloaded(title, pdfUrl);
              }

              double? progress = _downloadProgress[pdfUrl];
              bool isDownloading = progress != null;
              bool isDownloaded = _downloadedStatus[pdfUrl] ?? false;

              return Card(
                elevation: isDark ? 0 : 3,
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.transparent),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.primaryLight,
                    child: Icon(Icons.menu_book, color: isDark ? AppTheme.primaryDark : Colors.white),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Author: $author', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                  ),
                  trailing: isDownloading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: AppTheme.accentGreen,
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      kIsWeb
                          ? Icons.visibility
                          : (isDownloaded ? Icons.check_circle : Icons.download_rounded), // 🚀 Downloaded hone par tick/check_circle icon show hoga
                      color: isDownloaded ? Colors.green : (isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                      size: 26,
                    ),
                    onPressed: () => _downloadAndOpenPDF(context, pdfUrl, title),
                    tooltip: kIsWeb ? 'View Book' : (isDownloaded ? 'Read Book' : 'Download & Read'),
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