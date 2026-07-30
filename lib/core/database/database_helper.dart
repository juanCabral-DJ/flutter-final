import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DatabaseHelper gestiona la conexión y operaciones de base de datos.
/// Utiliza SQLite estricto para plataformas nativas (Windows, Android, iOS, Linux, Mac)
/// y almacenamiento de navegador (SharedPreferences / localStorage) para entorno Web.
class DatabaseHelper {
  static const String _databaseName = "trading_journal.db";
  static const int _databaseVersion = 1;

  static const String tableTrades = "trades";

  // Nombres de columnas
  static const String columnId = "id";
  static const String columnAsset = "asset";
  static const String columnStrategy = "strategy";
  static const String columnEntryDate = "entry_date";
  static const String columnRiskReward = "risk_reward_ratio";
  static const String columnOutcome = "outcome";
  static const String columnSession = "session";
  static const String columnNotes = "notes";
  static const String columnImageUrl = "image_url";

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Almacén para compatibilidad web con persistencia en localStorage/SharedPreferences
  final List<Map<String, dynamic>> _webMemoryStorage = [];
  int _webAutoIncrementId = 1;
  bool _webInitialized = false;

  Future<void> _ensureWebInitialized() async {
    if (!kIsWeb || _webInitialized) return;
    _webInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('trading_journal_web_trades');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _webMemoryStorage.clear();
        int maxId = 0;
        for (final item in decoded) {
          if (item is Map) {
            final mapItem = Map<String, dynamic>.from(item);
            _webMemoryStorage.add(mapItem);
            final id = mapItem[columnId];
            if (id is int && id > maxId) {
              maxId = id;
            }
          }
        }
        _webAutoIncrementId = maxId + 1;
      }
    } catch (e) {
      debugPrint('Error al cargar datos web persistentes: $e');
    }
  }

  Future<void> _saveWebStorage() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_webMemoryStorage);
      await prefs.setString('trading_journal_web_trades', jsonString);
    } catch (e) {
      debugPrint('Error al guardar datos web persistentes: $e');
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos sqflite en plataformas nativas.
  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        // Migración transparente para tablas nativas existentes
        try {
          await db.execute('ALTER TABLE $tableTrades ADD COLUMN $columnSession TEXT DEFAULT "newYork"');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE $tableTrades ADD COLUMN $columnNotes TEXT DEFAULT ""');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE $tableTrades ADD COLUMN $columnImageUrl TEXT');
        } catch (_) {}
      },
    );
  }

  /// Crea la tabla `trades` en SQLite nativo.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTrades (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnAsset TEXT NOT NULL,
        $columnStrategy TEXT NOT NULL,
        $columnEntryDate TEXT NOT NULL,
        $columnRiskReward REAL NOT NULL,
        $columnOutcome TEXT NOT NULL,
        $columnSession TEXT NOT NULL DEFAULT 'newYork',
        $columnNotes TEXT NOT NULL DEFAULT '',
        $columnImageUrl TEXT
      )
    ''');
  }

  // --- MÉTODOS CRUD BASE ---

  /// Inserta un nuevo registro en la base de datos
  Future<int> insertTrade(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      final newRow = Map<String, dynamic>.from(row);
      final id = _webAutoIncrementId++;
      newRow[columnId] = id;
      _webMemoryStorage.add(newRow);
      await _saveWebStorage();
      return id;
    }

    final db = (await database)!;
    return await db.insert(tableTrades, row);
  }

  /// Consulta todos los trades ordenados por fecha descendente
  Future<List<Map<String, dynamic>>> getTrades() async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      final list = List<Map<String, dynamic>>.from(_webMemoryStorage);
      list.sort((a, b) => (b[columnEntryDate] as String).compareTo(a[columnEntryDate] as String));
      return list;
    }

    final db = (await database)!;
    return await db.query(tableTrades, orderBy: '$columnEntryDate DESC');
  }

  /// Actualiza un registro existente según su id
  Future<int> updateTrade(Map<String, dynamic> row) async {
    final int id = row[columnId];

    if (kIsWeb) {
      await _ensureWebInitialized();
      final index = _webMemoryStorage.indexWhere((element) => element[columnId] == id);
      if (index != -1) {
        _webMemoryStorage[index] = Map<String, dynamic>.from(row);
        await _saveWebStorage();
        return 1;
      }
      return 0;
    }

    final db = (await database)!;
    return await db.update(
      tableTrades,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un registro por su id
  Future<int> deleteTrade(int id) async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      final initialLength = _webMemoryStorage.length;
      _webMemoryStorage.removeWhere((element) => element[columnId] == id);
      if (_webMemoryStorage.length != initialLength) {
        await _saveWebStorage();
      }
      return initialLength - _webMemoryStorage.length;
    }

    final db = (await database)!;
    return await db.delete(
      tableTrades,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
