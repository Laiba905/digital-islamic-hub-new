import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class DBHelper {
  static Database? _db;
  static Database? _hadithDb;

  static bool _isDbInited = false;
  static bool _isHadithInited = false;

  // 1. QURAN DATABASE
  static Future<Database?> get db async {
    if (_db != null && _db!.isOpen) return _db;
    _db = await initQuranDb();
    return _db;
  }

  static Future<Database> initQuranDb() async {
    if (_isDbInited && _db != null) return _db!;

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "quran_data.db");
    var exists = await databaseExists(path);

    if (!exists) {
      print("📦 Copying Quran Database from assets...");
      await Directory(dirname(path)).create(recursive: true);

      // Load and write data
      ByteData data = await rootBundle.load(join("assets/database", "quran_final_authentic_v2.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ Quran Database copied!");
    }

    _db = await openDatabase(path, readOnly: true);
    _isDbInited = true;
    return _db!;
  }

  // 2. HADITH DATABASE
  static Future<Database?> get hadithDb async {
    if (_hadithDb != null && _hadithDb!.isOpen) return _hadithDb;
    _hadithDb = await initHadithDb();
    return _hadithDb;
  }

  static Future<Database> initHadithDb() async {
    if (_isHadithInited && _hadithDb != null) return _hadithDb!;

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "hadith_database.db");
    var exists = await databaseExists(path);

    if (!exists) {
      print("📦 Copying Hadith Database from assets...");
      await Directory(dirname(path)).create(recursive: true);

      ByteData data = await rootBundle.load(join("assets/database", "hadith_database.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ Hadith Database copied!");
    }

    _hadithDb = await openDatabase(path, readOnly: true);
    _isHadithInited = true;
    return _hadithDb!;
  }

  // Common Methods
  static Future<List<Map<String, dynamic>>> getSurahList() async {
    final dbClient = await db;
    if (dbClient == null) return [];
    return await dbClient.rawQuery("SELECT DISTINCT surah_no FROM quran_data ORDER BY surah_no ASC");
  }

  static Future<List<Map<String, dynamic>>> getAyahsBySurah(int surahNo) async {
    final dbClient = await db;
    if (dbClient == null) return [];
    return await dbClient.query('quran_data', where: 'surah_no = ?', whereArgs: [surahNo], orderBy: 'ayah_no ASC');
  }

  static Future<List<Map<String, dynamic>>> getChaptersByBook(String collectionName) async {
    String book = collectionName.toLowerCase().trim();

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

  static Future<List<Map<String, dynamic>>> getHadithsByRange({
    required String collectionName,
    required int startNo,
    required int endNo,
  }) async {
    final dbClient = await hadithDb;
    if (dbClient == null) return [];
    String searchPattern = "%${collectionName.toLowerCase().trim()}%";
    return await dbClient.rawQuery(
        "SELECT * FROM hadiths WHERE LOWER(collection) LIKE ? AND CAST(hadith_no AS INTEGER) BETWEEN ? AND ? ORDER BY CAST(hadith_no AS INTEGER) ASC",
        [searchPattern, startNo, endNo]
    );
  }
}