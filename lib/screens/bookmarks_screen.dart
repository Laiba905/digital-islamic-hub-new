import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/database/db_helper.dart';
import '../services/bookmark_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isLoadingHadiths = false;
  List<Map<String, dynamic>> _bookmarkedHadithsList = [];

  // 🚀 Function to load detailed text from SQLite for all bookmarked IDs
  void _loadBookmarkedHadithsDetails(List<dynamic> bookmarkIds) async {
    if (bookmarkIds.isEmpty) {
      if (_bookmarkedHadithsList.isNotEmpty) {
        setState(() => _bookmarkedHadithsList = []);
      }
      return;
    }

    // Prevent rebuilding loop if lengths are identical
    if (_bookmarkedHadithsList.length == bookmarkIds.length && !_isLoadingHadiths) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _isLoadingHadiths = true);

      List<Map<String, dynamic>> tempHadiths = [];
      final dbClient = await DBHelper.hadithDb;

      if (dbClient != null) {
        for (String id in bookmarkIds) {
          List<String> parts = id.split('_');
          if (parts.length < 2) continue;

          String collection = parts[0];
          String hadithNo = parts[1];

          List<Map<String, dynamic>> res = await dbClient.rawQuery(
              "SELECT * FROM hadiths WHERE LOWER(collection) LIKE ? AND hadith_no = ?",
              ['%${collection.toLowerCase().trim()}%', hadithNo]
          );

          if (res.isNotEmpty) {
            var mutableMap = Map<String, dynamic>.from(res.first);
            mutableMap['display_collection'] = collection.toLowerCase().contains("dawud") ? "Sunan Abu Dawud" : "Jami at-Tirmidhi";
            tempHadiths.add(mutableMap);
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookmarkedHadithsList = tempHadiths;
          _isLoadingHadiths = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text("Hadith Bookmarks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookmarkService.getBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _bookmarkedHadithsList.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          List bookmarkIds = [];
          if (snapshot.hasData && snapshot.data!.exists) {
            bookmarkIds = (snapshot.data!.data() as Map)['hadith_bookmarks'] ?? [];
          }

          if (bookmarkIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 60, color: isDark ? Colors.white30 : Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "No bookmarked Hadiths yet.",
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          _loadBookmarkedHadithsDetails(bookmarkIds);

          if (_isLoadingHadiths && _bookmarkedHadithsList.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _bookmarkedHadithsList.length,
            itemBuilder: (context, i) {
              final h = _bookmarkedHadithsList[i];
              String rawCollection = h['collection'] ?? '';
              String hNo = h['hadith_no']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h['display_collection'] ?? 'Hadith Book',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Hadith Number: $hNo",
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        // ❌ Remove from bookmarks button (Crash Fixed)
                        IconButton(
                          icon: const Icon(Icons.bookmark_remove, color: Colors.redAccent),
                          tooltip: "Remove Bookmark",
                          onPressed: () async {
                            int? parsedNo = int.tryParse(hNo);
                            if (parsedNo != null && rawCollection.isNotEmpty) {
                              await _bookmarkService.toggleBookmark(rawCollection, parsedNo);
                              setState(() {
                                _bookmarkedHadithsList.removeAt(i);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: isDark ? Colors.white12 : Colors.grey.withAlpha(40)),
                    ),
                    // 🕌 Arabic Text (Contrast & Readability Fixed)
                    Text(
                      h['text_ar'] ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                          height: 1.8
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 📝 Urdu Translation Text
                    Text(
                      h['text_ur'] ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
                          height: 1.6
                      ),
                    ),
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