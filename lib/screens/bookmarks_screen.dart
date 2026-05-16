import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/database/db_helper.dart';
import '../services/bookmark_service.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  // Bookmark ID ("Abu Dawud_15") se local database data fetch karne ka function
  Future<Map<String, dynamic>?> _fetchHadithDetails(String bookmarkId) async {
    List<String> parts = bookmarkId.split('_');
    String collection = parts[0];
    int hadithNo = int.parse(parts[1]);

    final dbClient = await DBHelper.hadithDb;
    List<Map<String, dynamic>> res = await dbClient!.query(
      'hadiths', // Aap ka table name
      where: 'collection = ? AND hadith_no = ?',
      whereArgs: [collection, hadithNo],
    );
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final BookmarkService bookmarkService = BookmarkService();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text("My Bookmarks", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: bookmarkService.getBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("No Bookmarks saved yet."));

          List savedIds = (snapshot.data!.data() as Map)['hadith_bookmarks'] ?? [];
          if (savedIds.isEmpty) return const Center(child: Text("No Bookmarks saved yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: savedIds.length,
            itemBuilder: (context, i) {
              String currentId = savedIds[i];
              List<String> parts = currentId.split('_');
              String bookLabel = parts[0] == "Abu Dawud" ? "Sunan Abu Dawud" : "Jami at-Tirmidhi";

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchHadithDetails(currentId),
                builder: (context, hSnapshot) {
                  if (!hSnapshot.hasData || hSnapshot.data == null) return const SizedBox.shrink();
                  var hadith = hSnapshot.data!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("$bookLabel - No. ${hadith['hadith_no']}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () => bookmarkService.toggleBookmark(parts[0], hadith['hadith_no']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hadith['text_ur'],
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}