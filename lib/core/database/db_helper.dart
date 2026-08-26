import 'package:flutter/foundation.dart'; // 🚀 Added for kIsWeb
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// 🚀 FIXED: Removed dart:io import

class DBHelper {
  static Database? _db;
  static Database? _hadithDb;

  static Future<Database?> get db async {
    if (kIsWeb) return null; // Web par database support nahi hai
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  static Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "quran_data.db");
    
    // Web par databaseExists crash kar sakta hai, isliye upar kIsWeb check zaroori hai
    var exists = await databaseExists(path);

    if (!exists) {
      ByteData data = await rootBundle.load(join("assets/database", "quran_final_authentic_v2.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // sqflite handle karta hai agar hum database create karna chahein
      // Lekin File() use nahi karenge taake dart:io se bacha ja sake
    }
    return await openDatabase(path, readOnly: true);
  }

  static Future<Database?> get hadithDb async {
    if (kIsWeb) return null;
    if (_hadithDb != null) return _hadithDb;
    _hadithDb = await initHadithDb();
    return _hadithDb;
  }

  static Future<Database> initHadithDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "hadith_database.db");
    return await openDatabase(path, readOnly: true);
  }

  static Future<List<Map<String, dynamic>>> getChaptersByBook(String collectionName) async {
    // Basic mock data for Web taake app crash na ho
    if (kIsWeb) {
      return [{"chapter_no": "1", "chapter_name": "Web Preview (Database disabled)", "start_no": 1, "end_no": 10}];
    }
    
    String book = collectionName.toLowerCase().trim();
    if (book.contains("dawud")) {
      return [
        {"chapter_no": "1", "chapter_name": "Book of Purification (Kitab Al-Taharah)", "start_no": 1, "end_no": 50},
        {"chapter_no": "2", "chapter_name": "Book of Prayer (Kitab Al-Salat)", "start_no": 51, "end_no": 120},
      ];
    }
    return [{"chapter_no": "1", "chapter_name": "General Chapter", "start_no": 1, "end_no": 100}];
  }

  static Future<List<Map<String, dynamic>>> getHadithsByRange({
    required String collectionName,
    required String tableName,
    required int startNo,
    required int endNo,
  }) async {
    if (kIsWeb) return [];
    try {
      final dbClient = await hadithDb;
      if (dbClient == null) return [];

      const String rawQuery = '''
        SELECT * FROM hadiths 
        WHERE LOWER(collection) LIKE ? 
        AND CAST(hadith_no AS INTEGER) BETWEEN ? AND ?
        ORDER BY CAST(hadith_no AS INTEGER) ASC
      ''';

      String searchPattern = "%${collectionName.toLowerCase().trim()}%";
      return await dbClient.rawQuery(rawQuery, [searchPattern, startNo, endNo]);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSurahList() async {
    if (kIsWeb) return [];
    final dbClient = await db;
    if (dbClient == null) return [];
    return await dbClient.rawQuery("SELECT DISTINCT surah_no FROM quran_data ORDER BY surah_no ASC");
  }

  static Future<List<Map<String, dynamic>>> getAyahsBySurah(int surahNo) async {
    if (kIsWeb) return [];
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
