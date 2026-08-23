import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/surah_model.dart';

class AyahDetailScreen extends StatefulWidget {
  final int surahNo;
  const AyahDetailScreen({super.key, required this.surahNo});

  @override
  State<AyahDetailScreen> createState() => _AyahDetailScreenState();
}

class _AyahDetailScreenState extends State<AyahDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Surah currentSurah = Surah.getSurahByNo(widget.surahNo);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: Text("${currentSurah.nameEn} (${currentSurah.nameAr})"),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getAyahsBySurah(widget.surahNo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData) return const Center(child: Text("No Data Found"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              Ayah ayah = Ayah.fromMap(snapshot.data![index]);
              String arabicText = ayah.arabicText;

              // --- BISMILLAH HANDLING ---
              if (widget.surahNo != 1 && widget.surahNo != 9 && ayah.ayahNo == 1) {
                final List<String> bismillahPatterns = [
                  "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                  "بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ",
                ];
                for (var pattern in bismillahPatterns) {
                  if (arabicText.startsWith(pattern)) {
                    arabicText = arabicText.replaceFirst(pattern, "").trim();
                    break;
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.green.shade50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ayah Number Badge (Share icon removed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("Ayah ${ayah.ayahNo}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),

                    // Bismillah Header
                    if (widget.surahNo != 1 && widget.surahNo != 9 && ayah.ayahNo == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        child: Text(
                          "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // Arabic Text
                    Text(
                      arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 26,
                          height: 1.9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF003D33)
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),

                    // Urdu Translation
                    Text(
                      ayah.urduTrans,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : const Color(0xFF004D40),
                          height: 1.5
                      ),
                    ),

                    const SizedBox(height: 12),

                    // English Translation
                    Text(
                      ayah.engTrans,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.blueGrey[600],
                          height: 1.4
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tafseer Section with Toggle Icons
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        // 'controlAffinity' is default trailing,
                        // ExpansionTile automatically switches the arrow icon when opened/closed.
                        title: const Text("Tafseer (Urdu & English)",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text("Urdu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                Text(ayah.urduTafseer,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                const Divider(height: 25, color: Colors.white10),
                                const Text("English:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                Text(ayah.engTafseer.isNotEmpty ? ayah.engTafseer : "Commentary not available.",
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                              ],
                            ),
                          ),
                        ],
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