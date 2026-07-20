import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ScholarPaymentsScreen extends StatefulWidget {
  final String scholarId; // 🌟 Naya parameter: ab ye screen scholar ID receive karegi

  const ScholarPaymentsScreen({super.key, required this.scholarId});

  @override
  State<ScholarPaymentsScreen> createState() => _ScholarPaymentsScreenState();
}

class _ScholarPaymentsScreenState extends State<ScholarPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Scholar Payments Record"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🌟 Current user ke bajaye widget.scholarId ka use ho raha hai
        stream: FirebaseFirestore.instance
            .collection('scholar_payments')
            .where('scholarId', isEqualTo: widget.scholarId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, paySnap) {
          if (paySnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!paySnap.hasData || paySnap.data!.docs.isEmpty) {
            return const Center(child: Text("No payment history found for this scholar."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: paySnap.data!.docs.length,
            itemBuilder: (context, index) {
              final payData = paySnap.data!.docs[index].data() as Map<String, dynamic>;

              final screenshotUrl = payData['receiptScreenshotUrl'];
              final amount = payData['amount'] ?? 0;
              final date = (payData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: (screenshotUrl != null && screenshotUrl.toString().isNotEmpty)
                      ? Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        screenshotUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                      : const Icon(Icons.payment, color: Colors.green),

                  title: Text("Rs. $amount", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date)),

                  trailing: (screenshotUrl != null)
                      ? IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.green),
                    onPressed: () => _showScreenshot(context, screenshotUrl),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showScreenshot(BuildContext context, String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(url),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }
}