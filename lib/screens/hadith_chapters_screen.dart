import 'package:flutter/material.dart';
import 'hadith_list_screen.dart';

class HadithChaptersScreen extends StatefulWidget {
  final String collectionName; // "Abu Dawud" ya "Tirmidhi"
  final String displayName;   // "Sunan Abu Dawud" ya "Jami at-Tirmidhi"

  const HadithChaptersScreen({
    super.key,
    required this.collectionName,
    required this.displayName
  });

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChapters = [];

  // Abu Dawud aur Tirmidhi ke standard chapters aur unki Hadees number ranges
  final Map<String, List<Map<String, dynamic>>> _bookChapters = {
    "Abu Dawud": [
      {"no": 1, "name_en": "Book of Purification (Taharah)", "name_ur": "کتاب الطہارت", "start": 1, "end": 390},
      {"no": 2, "name_en": "Book of Prayer (Salat)", "name_ur": "کتاب الصلوۃ", "start": 391, "end": 1160},
      {"no": 3, "name_en": "Book of Zakat", "name_ur": "کتاب الزکوۃ", "start": 1161, "end": 1180},
      {"no": 4, "name_en": "Book of Fasting (Siyam)", "name_ur": "کتاب الصوم", "start": 1181, "end": 1500},
      // Aap apni database ke hisab se mazeed ranges yahan add kar sakti hain
    ],
    "Tirmidhi": [
      {"no": 1, "name_en": "Book of Purification", "name_ur": "کتاب الطہارت", "start": 1, "end": 148},
      {"no": 2, "name_en": "Book of Prayer", "name_ur": "کتاب الصلوۃ", "start": 149, "end": 428},
      {"no": 3, "name_en": "Book of Zakat", "name_ur": "کتاب الزکوۃ", "start": 429, "end": 510},
    ]
  };

  @override
  void initState() {
    super.initState();
    _filteredChapters = _bookChapters[widget.collectionName] ?? [];
  }

  void _filterSearch(String query) {
    List<Map<String, dynamic>> allChapters = _bookChapters[widget.collectionName] ?? [];
    setState(() {
      if (query.isEmpty) {
        _filteredChapters = allChapters;
      } else {
        _filteredChapters = allChapters.where((ch) {
          final nameEn = ch['name_en'].toString().toLowerCase();
          final nameUr = ch['name_ur'].toString().toLowerCase();
          final no = ch['no'].toString();
          final q = query.toLowerCase();

          return nameEn.contains(q) || nameUr.contains(q) || no == q;
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
        title: Text("${widget.displayName} - Chapters"),
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Chapter Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search Chapter by name or number...",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(10) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _filteredChapters.isEmpty
                ? const Center(child: Text("No Chapters Found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _filteredChapters.length,
              itemBuilder: (context, index) {
                var ch = _filteredChapters[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withAlpha(40),
                      child: Text("${ch['no']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      ch['name_en'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Text(
                      "Hadith: ${ch['start']} - ${ch['end']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: Text(
                      ch['name_ur'],
                      style: const TextStyle(fontFamily: 'UrduFont', color: Colors.green, fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HadithListScreen(
                            collectionName: widget.collectionName,
                            displayName: widget.displayName,
                            chapterName: ch['name_en'],
                            startNo: ch['start'],
                            endNo: ch['end'],
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