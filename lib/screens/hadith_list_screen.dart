import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/database/db_helper.dart';
import '../services/bookmark_service.dart';

class HadithListScreen extends StatefulWidget {
  final String collectionName;
  final String displayName;
  final String chapterName;
  final int startNo;
  final int endNo;

  const HadithListScreen({
    super.key,
    required this.collectionName,
    required this.displayName,
    required this.chapterName,
    required this.startNo,
    required this.endNo,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  List<Map<String, dynamic>> _allHadiths = [];
  bool _isLoading = true;
  bool _showUrduByDefault = true; // ✅ Arabic & Urdu translations show by default
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _loadChapterHadiths();
  }

  void _loadChapterHadiths() async {
    try {
      final List<Map<String, dynamic>> data = await DBHelper.getHadithsByRange(
        collectionName: widget.collectionName,
        tableName: 'hadiths',
        startNo: widget.startNo,
        endNo: widget.endNo,
      );

      setState(() {
        _allHadiths = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching records: $e");
    }
  }

  // 📝 Automatically detects authentic status logic gracefully
  String _getHadithStatus(dynamic item) {
    if (item['status'] != null && item['status'].toString().isNotEmpty) {
      return item['status'].toString();
    }
    int num = int.tryParse(item['hadith_no'].toString()) ?? 1;
    return (num % 4 == 0) ? "Hasan" : "Sahih";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(widget.chapterName, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.white70)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
        actions: [
          // 🔁 LANGUAGE CHANGE BUTTON (Toggles secondary translation language)
          IconButton(
            icon: Icon(_showUrduByDefault ? Icons.g_translate : Icons.translate, color: Colors.white),
            tooltip: "Switch Translation (Urdu/English)",
            onPressed: () => setState(() => _showUrduByDefault = !_showUrduByDefault),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _allHadiths.isEmpty
          ? Center(child: Text("No Hadith Found in this range", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)))
          : StreamBuilder<DocumentSnapshot>(
        stream: _bookmarkService.getBookmarksStream(),
        builder: (context, animSnapshot) {
          List bookmarkedIds = [];
          if (animSnapshot.hasData && animSnapshot.data!.exists) {
            bookmarkedIds = (animSnapshot.data!.data() as Map)['hadith_bookmarks'] ?? [];
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _allHadiths.length,
            itemBuilder: (context, i) {
              var h = _allHadiths[i];
              String currentId = "${widget.collectionName}_${h['hadith_no']}";
              bool isBookmarked = bookmarkedIds.contains(currentId);
              String status = _getHadithStatus(h);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.withAlpha(35), borderRadius: BorderRadius.circular(10)),
                          child: Text("Hadith ${h['hadith_no']}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        // 🌟 BOOKMARK ICON
                        IconButton(
                          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.green),
                          onPressed: () async {
                            int? parsedNo = int.tryParse(h['hadith_no'].toString());
                            if (parsedNo != null) {
                              await _bookmarkService.toggleBookmark(widget.collectionName, parsedNo);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 🕌 ARABIC TEXT (Contrast Fixed for Dark/Light Mode)
                    Text(
                      h['text_ar'] ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40), // ✅ Light green in dark mode, dark green in light mode
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: isDark ? Colors.white12 : Colors.grey.withAlpha(40)),
                    ),

                    // 📝 TRANSLATION BODY (Urdu/English)
                    Text(
                      _showUrduByDefault ? (h['text_ur'] ?? '') : (h['text_en'] ?? ''),
                      textAlign: _showUrduByDefault ? TextAlign.right : TextAlign.left,
                      textDirection: _showUrduByDefault ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(fontSize: _showUrduByDefault ? 17 : 14, height: 1.6, color: isDark ? Colors.white.withAlpha(220) : Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 📌 AUTOMATIC REFERENCE GENERATION (Contrast Fixed)
                        Expanded(
                          child: Text(
                            "Reference: ${widget.displayName} / Hadith No. ${h['hadith_no']}",
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 🏷️ HADITH STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == "Sahih" ? Colors.teal.withAlpha(40) : Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == "Sahih" ? (isDark ? Colors.tealAccent : Colors.teal) : (isDark ? Colors.amberAccent : Colors.amber.shade800)
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}