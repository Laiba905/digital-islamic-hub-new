import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import 'hadith_list_screen.dart';
import '../theme/app_theme.dart';

class HadithChaptersScreen extends StatefulWidget {
  final String collectionName;
  final String displayName;

  const HadithChaptersScreen({
    super.key,
    required this.collectionName,
    required this.displayName,
  });

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allChapters = [];
  List<Map<String, dynamic>> _filteredChapters = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  void _loadChapters() async {
    final data = await DBHelper.getChaptersByBook(widget.collectionName);
    setState(() {
      _allChapters = data;
      _filteredChapters = data;
      _isLoading = false;
    });
  }

  void _filterChapters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChapters = _allChapters;
      } else {
        final cleanQuery = query.toLowerCase().trim();
        _filteredChapters = _allChapters.where((ch) {
          final name = ch['chapter_name'].toString().toLowerCase();
          final num = ch['chapter_no'].toString();
          return name.contains(cleanQuery) || num == cleanQuery;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterChapters,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search chapter by name or number...",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
                : _filteredChapters.isEmpty
                ? Center(child: Text("No Chapters Found", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _filteredChapters.length,
              itemBuilder: (context, index) {
                final chapter = _filteredChapters[index];

                String chNo = chapter['chapter_no'].toString();
                String chName = chapter['chapter_name'].toString();
                int startNo = chapter['start_no'];
                int endNo = chapter['end_no'];

                return Card(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: isDark ? 0 : 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isDark ? AppTheme.accentGreen.withAlpha(40) : AppTheme.primaryLight.withAlpha(15),
                      child: Text(
                        chNo,
                        style: TextStyle(color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      chName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Hadiths: $startNo - $endNo",
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HadithListScreen(
                            collectionName: widget.collectionName,
                            displayName: widget.displayName,
                            chapterName: chName,
                            startNo: startNo,
                            endNo: endNo,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}