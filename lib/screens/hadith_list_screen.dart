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
  List<Map<String, dynamic>> _filteredHadiths = [];
  bool _isLoading = true;
  bool _showUrdu = true; // State controls translation toggling
  final BookmarkService _bookmarkService = BookmarkService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChapterHadiths();
  }

  // Optimized query execution via explicit integer range bounds
  void _loadChapterHadiths() async {
    try {
      final dbClient = await DBHelper.hadithDb;
      if (dbClient == null) {
        print("Database client is null!");
        return;
      }

      print("Querying database parameters: ${widget.collectionName} range [${widget.startNo} - ${widget.endNo}]");

      // CAST syntax standardizes numeric string comparison evaluations
      final List<Map<String, dynamic>> data = await dbClient.query(
        'hadiths',
        where: 'collection = ? AND CAST(hadith_no AS INTEGER) BETWEEN ? AND ?',
        whereArgs: [widget.collectionName, widget.startNo, widget.endNo],
        orderBy: 'CAST(hadith_no AS INTEGER) ASC',
      );

      print("Operation success. Processed records count: ${data.length}");

      setState(() {
        _allHadiths = data;
        _filteredHadiths = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading chapter hadiths: $e");
    }
  }

  // Functional content matching layer for localized languages or exact indexes
  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHadiths = _allHadiths;
      } else {
        _filteredHadiths = _allHadiths.where((h) {
          final textEn = h['text_en'] != null ? h['text_en'].toString().toLowerCase() : '';
          final textUr = h['text_ur'] != null ? h['text_ur'].toString().toLowerCase() : '';
          final no = h['hadith_no'] != null ? h['hadith_no'].toString() : '';
          final q = query.toLowerCase();

          return textEn.contains(q) || textUr.contains(q) || no == q;
        }).toList();
      }
    });
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
            Text(
                widget.chapterName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 2),
            Text(
                widget.displayName,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.white70),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showUrdu ? Icons.g_translate : Icons.translate, color: Colors.white),
            tooltip: "Switch Translation Language",
            onPressed: () => setState(() => _showUrdu = !_showUrdu),
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Engine Context Input Field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search in this chapter...",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterSearch("");
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(10) : Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _filteredHadiths.isEmpty
                ? Center(
              child: Text(
                "No Hadith Found",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16),
              ),
            )
                : StreamBuilder<DocumentSnapshot>(
              stream: _bookmarkService.getBookmarksStream(),
              builder: (context, animSnapshot) {
                List bookmarkedIds = [];
                if (animSnapshot.hasData && animSnapshot.data!.exists) {
                  bookmarkedIds = (animSnapshot.data!.data() as Map)['hadith_bookmarks'] ?? [];
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  itemCount: _filteredHadiths.length,
                  itemBuilder: (context, i) {
                    var h = _filteredHadiths[i];
                    String currentId = "${widget.collectionName}_${h['hadith_no']}";
                    bool isBookmarked = bookmarkedIds.contains(currentId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark ? Colors.white10 : Colors.green.shade50
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 2)
                            )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(40),
                                    borderRadius: BorderRadius.circular(12)
                                ),
                                child: Text(
                                    "Hadith ${h['hadith_no']}",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: Colors.green
                                ),
                                onPressed: () => _bookmarkService.toggleBookmark(
                                    widget.collectionName, h['hadith_no']
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          // Localized Text Rendering Container View
                          Text(
                            _showUrdu ? (h['text_ur'] ?? '') : (h['text_en'] ?? ''),
                            textAlign: _showUrdu ? TextAlign.right : TextAlign.left,
                            textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: _showUrdu ? 19 : 15,
                              height: 1.6,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: _showUrdu ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}