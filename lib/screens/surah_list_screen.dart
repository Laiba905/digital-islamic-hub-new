import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/database/db_helper.dart';
import '../models/surah_model.dart';
import 'ayah_detail_screen.dart';
import '../theme/app_theme.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<Map<String, dynamic>> _allSurahs = [];
  List<Map<String, dynamic>> _foundSurahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  void _fetchSurahs() async {
    final data = await DBHelper.getSurahList();
    setState(() {
      _allSurahs = data;
      _foundSurahs = data;
      _isLoading = false;
    });
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allSurahs;
    } else {
      results = _allSurahs.where((surah) {
        int sNo = surah['surah_no'];
        String sName = Surah.surahNamesEn[sNo - 1].toLowerCase();
        return sName.contains(enteredKeyword.toLowerCase()) ||
            sNo.toString().contains(enteredKeyword);
      }).toList();
    }
    setState(() {
      _foundSurahs = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Al-Quran", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              onChanged: (value) => _runFilter(value),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search Surah Name or Number',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _foundSurahs.length,
              itemBuilder: (context, index) {
                int surahNo = _foundSurahs[index]['surah_no'];
                Surah s = Surah.getSurahByNo(surahNo);

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(13) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.green.shade50,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4)
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      leading: Container(
                        height: 45, width: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.accentGreen.withAlpha(30) : AppTheme.primaryLight.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(surahNo.toString(),
                            style: TextStyle(
                              color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight, 
                              fontWeight: FontWeight.bold
                            )),
                      ),
                      title: Text(s.nameEn,
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Text("${s.type} • ${s.totalAyahs} Ayahs",
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                      trailing: Text(s.nameAr,
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: isDark ? AppTheme.accentGreen : AppTheme.primaryLight
                          )),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AyahDetailScreen(surahNo: surahNo),
                          ),
                        );
                      },
                    ),
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