import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart'; // 🚀 Audio Player Import
import '../core/database/db_helper.dart';
import '../models/surah_model.dart';

class AyahDetailScreen extends StatefulWidget {
  final int surahNo;
  const AyahDetailScreen({super.key, required this.surahNo});

  @override
  State<AyahDetailScreen> createState() => _AyahDetailScreenState();
}

class _AyahDetailScreenState extends State<AyahDetailScreen> {
  // 🚀 Audio player instance aur state manager variables
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingAyahNo;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    // Audio mukammal khatam hone par play state reset karne ka listener
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _currentlyPlayingAyahNo = null;
        _isLoadingAudio = false;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Screen se bahar jane par player ko destroy karna zaroori hai
    super.dispose();
  }

  // 🚀 Audio play ya stop karne ka function
  Future<void> _handleAudioPlayback(int surahNo, int ayahNo) async {
    // Agar wahi ayah dobara click ho jo pehle se chal rahi hai, to usey stop kar do
    if (_currentlyPlayingAyahNo == ayahNo) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingAyahNo = null;
        _isLoadingAudio = false;
      });
      return;
    }

    try {
      setState(() {
        _currentlyPlayingAyahNo = ayahNo;
        _isLoadingAudio = true;
      });

      // Format Surah and Ayah numbers into 3-digit strings (e.g., 1 -> 001, 7 -> 007)
      String sNo = surahNo.toString().padLeft(3, '0');
      String aNo = ayahNo.toString().padLeft(3, '0');

      // Mishary Rashid Alafasy High Quality Audio Stream URL
      String audioUrl = "https://mirrors.quranicaudio.com/everyayah/Alafasy_128kbps/$sNo$aNo.mp3";

      await _audioPlayer.stop(); // Pehle se chalti hui koi bhi audio stop karein
      await _audioPlayer.play(UrlSource(audioUrl));

      setState(() {
        _isLoadingAudio = false;
      });
    } catch (e) {
      print("Audio Playback Error: $e");
      setState(() {
        _currentlyPlayingAyahNo = null;
        _isLoadingAudio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not load audio. Please check your internet connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Surah currentSurah = Surah.getSurahByNo(widget.surahNo);

    // Surah At-Tawbah (9) ke ilawa baqi sab me top standalone header aayega
    bool showTopBismillahHeader = widget.surahNo != 9;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: Text("${currentSurah.nameEn} (${currentSurah.nameAr})", style: const TextStyle(fontWeight: FontWeight.bold)),
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
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No Data Found"));

          final rawData = snapshot.data!;

          return ListView.builder(
            itemCount: showTopBismillahHeader ? rawData.length + 1 : rawData.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {

              // 🕋 CASE A: Display Global Top Bismillah Banner
              if (showTopBismillahHeader && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 25),
                  child: Center(
                    child: Text(
                      "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40),
                      ),
                    ),
                  ),
                );
              }

              // Index offset calculation
              final int actualDataIndex = showTopBismillahHeader ? index - 1 : index;

              Ayah ayah = Ayah.fromMap(rawData[actualDataIndex]);
              String arabicText = ayah.arabicText.trim();

              // 🚀 FIX FOR SURAH AL-FATIHA: Ayah 1 card ko hide karna taake double Bismillah na aaye
              if (widget.surahNo == 1 && ayah.ayahNo == 1) {
                return const SizedBox.shrink();
              }

              // 🚀 CASE B: Filtering internal duplicate Bismillah from Ayah 1 of other Surahs
              if (ayah.ayahNo == 1 && widget.surahNo != 9 && widget.surahNo != 1) {
                final List<String> exactDatabaseBismillahs = [
                  "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                  "بِسْمِ compressibility.اللهِ الرَّحْمَنِ الرَّحِيمِ",
                  "بِّسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
                ];

                bool matched = false;
                for (var pattern in exactDatabaseBismillahs) {
                  if (arabicText.startsWith(pattern)) {
                    arabicText = arabicText.replaceFirst(pattern, "").trim();
                    matched = true;
                    break;
                  }
                }

                if (!matched) {
                  List<String> words = arabicText.split(" ");
                  if (words.length > 4 && words[0].contains("بِ")) {
                    arabicText = words.sublist(4).join(" ").trim();
                  }
                }
              }

              if (arabicText.isEmpty && ayah.ayahNo == 1 && widget.surahNo != 1) {
                return const SizedBox.shrink();
              }

              // Check if this specific ayah is currently playing or buffering
              bool isThisAyahPlaying = _currentlyPlayingAyahNo == ayah.ayahNo;

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
                    // Top Row: Ayah Number Badge + Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ayah Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Ayah ${ayah.ayahNo}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),

                        // Actions Row: Audio Player + Share
                        Row(
                          children: [
                            // 🚀 AUDIO PLAY / STOP BUTTON
                            isThisAyahPlaying && _isLoadingAudio
                                ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
                              ),
                            )
                                : IconButton(
                              icon: Icon(
                                isThisAyahPlaying ? Icons.stop_circle_rounded : Icons.play_circle_outline_rounded,
                                color: isThisAyahPlaying
                                    ? Colors.red.shade400
                                    : (isDark ? Colors.green.shade300 : Colors.green.shade700),
                                size: 24,
                              ),
                              onPressed: () => _handleAudioPlayback(widget.surahNo, ayah.ayahNo),
                            ),

                            const SizedBox(width: 5),

                            // SHARE BUTTON
                            IconButton(
                              icon: Icon(
                                Icons.share_outlined,
                                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                                size: 20,
                              ),
                              onPressed: () {
                                final String shareText =
                                    "📖 *${currentSurah.nameEn} (${currentSurah.nameAr}) - Ayah ${ayah.ayahNo}*\n\n"
                                    "🟢 *Arabic:*\n$arabicText\n\n"
                                    "🔸 *Urdu Translation:*\n${ayah.urduTrans}\n\n"
                                    "🔹 *English Translation:*\n${ayah.engTrans}\n\n"
                                    "📱 Shared via Digital Islamic Hub App";

                                Share.share(shareText);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Beautiful Clean Arabic Text
                    Text(
                      arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003D33),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    const SizedBox(height: 10),

                    // Urdu Translation
                    Text(
                      ayah.urduTrans,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white.withAlpha(210) : const Color(0xFF004D40),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // English Translation
                    Text(
                      ayah.engTrans,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.blueGrey[600],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tafseer Box Area
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          "Tafseer (Urdu & English)",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text("Urdu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                const SizedBox(height: 4),
                                Text(
                                  ayah.urduTafseer,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
                                ),
                                const Text("English:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                const SizedBox(height: 4),
                                Text(
                                  ayah.engTafseer.isNotEmpty ? ayah.engTafseer : "Commentary not available.",
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                                ),
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