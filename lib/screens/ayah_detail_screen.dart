import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/surah_model.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("${currentSurah.nameEn} (${currentSurah.nameAr})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getAyahsBySurah(widget.surahNo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
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
                  boxShadow: isDark ? [] : [
                    BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.accentGreen.withAlpha(40) : AppTheme.primaryLight.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("Ayah ${ayah.ayahNo}",
                            style: TextStyle(color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),

                    if (widget.surahNo != 1 && widget.surahNo != 9 && ayah.ayahNo == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        child: Text(
                          "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              color: isDark ? Colors.white : AppTheme.primaryLight,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    Text(
                      arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 26,
                          height: 1.9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryLight
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    const SizedBox(height: 10),

                    Text(
                      ayah.urduTrans,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.5
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      ayah.engTrans,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          height: 1.4
                      ),
                    ),

                    const SizedBox(height: 10),

                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text("Tafseer (Urdu & English)",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)),
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
                                Text("Urdu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)),
                                Text(ayah.urduTafseer,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                const Divider(height: 25, color: Colors.white10),
                                Text("English:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight)),
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