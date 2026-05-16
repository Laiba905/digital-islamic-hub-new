import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;
  static Database? _hadithDb;

  // ==========================================================================
  // QURAN DATABASE GETTER & INIT
  // ==========================================================================
  static Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  static Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "quran_data.db");

    var exists = await databaseExists(path);

    // File exist na kare ya 0 KB ki corruption ho to assets se fresh copy kare
    if (!exists || (await File(path).exists() && await File(path).length() == 0)) {
      print("Quran Database nahi mila ya khali hai. Assets se copy ho raha hai...");
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets/database", "quran_final_authentic_v2.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      print("Quran Database kamyabi se copy ho gaya!");
    }
    return await openDatabase(path, readOnly: true);
  }

  // ==========================================================================
  // HADITH DATABASE GETTER & INIT
  // ==========================================================================
  static Future<Database?> get hadithDb async {
    if (_hadithDb != null) return _hadithDb;
    _hadithDb = await initHadithDb();
    return _hadithDb;
  }

  static Future<Database> initHadithDb() async {
    var databasesPath = await getDatabasesPath();
    // ⚠️ FIXED: Name consistent rakha hai 'hadith_database.db' taake file search clash na ho
    String path = join(databasesPath, "hadith_database.db");

    var exists = await databaseExists(path);

    // Robust Check: Agar file khali (0 KB) bani hui ho, to usey override karein
    if (!exists || (await File(path).exists() && await File(path).length() == 0)) {
      print("Hadith Database nahi mila ya khali hai. Fresh copy ho rahi hai...");
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets/database", "hadith_database.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      print("Hadith Database kamyabi se copy ho gaya!");
    }
    return await openDatabase(path, readOnly: true);
  }

  // ==========================================================================
  // DEBUGGING FUNCTIONS
  // ==========================================================================

  // Tables check karne ke liye (Quran)
  static Future<void> printTableNames() async {
    final dbClient = await db;
    var tables = await dbClient!.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('---------- DATABASE TABLES ----------');
    for (var table in tables) {
      print('Found Table: ${table['name']}');
    }
    print('-------------------------------------');
  }

  // Columns check karne ke liye (Quran)
  static Future<void> checkColumns() async {
    final dbClient = await db;
    List<Map<String, dynamic>> columns = await dbClient!.rawQuery("PRAGMA table_info(quran_data)");

    print('---------- COLUMN NAMES IN quran_data ----------');
    for (var column in columns) {
      print('Column: ${column['name']} (${column['type']})');
    }
    print('------------------------------------------------');
  }

  // Hadith Table ke Columns check karne ka function
  static Future<void> checkHadithColumns(String tableName) async {
    try {
      final dbClient = await hadithDb;
      List<Map<String, dynamic>> columns = await dbClient!.rawQuery("PRAGMA table_info($tableName)");
      print('---------- COLUMN NAMES IN $tableName ----------');
      for (var column in columns) {
        print('Column: ${column['name']} (${column['type']})');
      }
      print('------------------------------------------------');
    } catch (e) {
      print("Error checking hadith columns: $e");
    }
  }

  // ==========================================================================
  // QURAN METHODS
  // ==========================================================================

  static Future<List<Map<String, dynamic>>> getSurahList() async {
    final dbClient = await db;
    return await dbClient!.rawQuery("SELECT DISTINCT surah_no FROM quran_data ORDER BY surah_no ASC");
  }

  static Future<List<Map<String, dynamic>>> getAyahsBySurah(int surahNo) async {
    final dbClient = await db;
    return await dbClient!.query(
      'quran_data',
      where: 'surah_no = ?',
      whereArgs: [surahNo],
      orderBy: 'ayah_no ASC',
    );
  }

  // ==========================================================================
  // HADITH METHODS (Fully Fixed with Integer Cast Engine)
  // ==========================================================================

  // Pure collection wise load karne ke liye method (purana fallback)
  static Future<List<Map<String, dynamic>>> getHadithsByCollection(String collectionName, String tableName) async {
    try {
      final dbClient = await hadithDb;
      return await dbClient!.query(
        tableName,
        where: 'collection = ?',
        whereArgs: [collectionName],
        orderBy: 'CAST(hadith_no AS INTEGER) ASC',
      );
    } catch (e) {
      print("Error in getHadithsByCollection: $e");
      return [];
    }
  }

  // 🚀 NEW OPTIMIZED RANGE METHOD: Jo hamari nayi HadithListScreen use kar rahi hai chapters ke liye
  static Future<List<Map<String, dynamic>>> getHadithsByRange({
    required String collectionName,
    required String tableName,
    required int startNo,
    required int endNo,
  }) async {
    try {
      final dbClient = await hadithDb;
      if (dbClient == null) return [];

      return await dbClient.query(
        tableName,
        where: 'collection = ? AND CAST(hadith_no AS INTEGER) BETWEEN ? AND ?',
        whereArgs: [collectionName, startNo, endNo],
        orderBy: 'CAST(hadith_no AS INTEGER) ASC',
      );
    } catch (e) {
      print("Error fetching hadiths by range: $e");
      return [];
    }
  }
}