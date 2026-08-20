import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String localPath;
  final String title;

  const PdfViewerScreen({super.key, required this.localPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.file(
        File(localPath),
        canShowPaginationDialog: true,
        canShowScrollHead: true,
      ),
    );
  }
}