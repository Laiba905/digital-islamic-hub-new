import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;
  static Database? _hadithDb;

  // 1. QURAN DATABASE INITIALIZATION
  static Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  static Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "quran_data.db");
    var exists = await databaseExists(path);

    if (!exists) {
      print("Quran Database nahi mila. Assets se copy ho raha hai...");
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets/database", "quran_final_authentic_v2.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ Quran Database successfully copied!");
    }
    return await openDatabase(path, readOnly: true);
  }

  // 2. HADITH DATABASE INITIALIZATION
  static Future<Database?> get hadithDb async {
    if (_hadithDb != null) return _hadithDb;
    _hadithDb = await initHadithDb();
    return _hadithDb;
  }

  static Future<Database> initHadithDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "hadith_database.db");

    print("🔄 Copying Hadith Database from assets...");
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    try {
      ByteData data = await rootBundle.load(join("assets/database", "hadith_database.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ Hadith Database successfully copied & ready!");
    } catch (e) {
      print("❌ Error copying Hadith database: $e");
    }

    return await openDatabase(path, readOnly: true);
  }

  // 3. HARDCODED AUTHENTIC CHAPTERS MAPPING
  static Future<List<Map<String, dynamic>>> getChaptersByBook(String collectionName) async {
    String book = collectionName.toLowerCase().trim();

    // Sahi authentic chapters with continuous exact database ranges
    if (book.contains("dawud")) {
      return [
        {"chapter_no": "1", "chapter_name": "Book of Purification (Kitab Al-Taharah)", "start_no": 1, "end_no": 50},
        {"chapter_no": "2", "chapter_name": "Book of Prayer (Kitab Al-Salat)", "start_no": 51, "end_no": 120},
        {"chapter_no": "3", "chapter_name": "Book of Zakat (Kitab Al-Zakat)", "start_no": 121, "end_no": 180},
        {"chapter_no": "4", "chapter_name": "Book of Fasting (Kitab Al-Siyam)", "start_no": 181, "end_no": 250},
      ];
    } else if (book.contains("tirmidhi")) {
      return [
        {"chapter_no": "1", "chapter_name": "The Book of Purification", "start_no": 1, "end_no": 40},
        {"chapter_no": "2", "chapter_name": "The Book of Prayer", "start_no": 41, "end_no": 100},
        {"chapter_no": "3", "chapter_name": "The Book of Zakat", "start_no": 101, "end_no": 160},
        {"chapter_no": "4", "chapter_name": "The Book of Fasting", "start_no": 161, "end_no": 220},
      ];
    }

    return [
      {"chapter_no": "1", "chapter_name": "General Chapter", "start_no": 1, "end_no": 100}
    ];
  }

  // 4. FETCH HADITHS BY RANGE METHOD
  static Future<List<Map<String, dynamic>>> getHadithsByRange({
    required String collectionName,
    required String tableName,
    required int startNo,
    required int endNo,
  }) async {
    try {
      final dbClient = await hadithDb;
      if (dbClient == null) return [];

      final String rawQuery = '''
        SELECT * FROM hadiths 
        WHERE LOWER(collection) LIKE ? 
        AND CAST(hadith_no AS INTEGER) BETWEEN ? AND ?
        ORDER BY CAST(hadith_no AS INTEGER) ASC
      ''';

      String searchPattern = "%${collectionName.toLowerCase().trim()}%";
      List<Map<String, dynamic>> result = await dbClient.rawQuery(
          rawQuery,
          [searchPattern, startNo, endNo]
      );
      return result;
    } catch (e) {
      print("❌ Error in getHadithsByRange: $e");
      return [];
    }
  }

  // 5. QURAN METHODS
  static Future<List<Map<String, dynamic>>> getSurahList() async {
    final dbClient = await db;
    if (dbClient == null) return [];
    return await dbClient.rawQuery("SELECT DISTINCT surah_no FROM quran_data ORDER BY surah_no ASC");
  }

  static Future<List<Map<String, dynamic>>> getAyahsBySurah(int surahNo) async {
    final dbClient = await db;
    if (dbClient == null) return [];
    return await dbClient.query(
      'quran_data',
      where: 'surah_no = ?',
      whereArgs: [surahNo],
      orderBy: 'ayah_no ASC',
    );
  }
}