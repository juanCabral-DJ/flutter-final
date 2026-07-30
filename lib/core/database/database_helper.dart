import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DatabaseHelper gestiona la conexión y operaciones de base de datos con soporte multiusuario.
class DatabaseHelper {
  static const String _databaseName = "trading_journal.db";
  static const int _databaseVersion = 2;

  static const String tableTrades = "trades";
  static const String tableUsers = "users";

  // Nombres de columnas de Trades
  static const String columnId = "id";
  static const String columnUserId = "user_id";
  static const String columnAsset = "asset";
  static const String columnStrategy = "strategy";
  static const String columnEntryDate = "entry_date";
  static const String columnRiskReward = "risk_reward_ratio";
  static const String columnOutcome = "outcome";
  static const String columnSession = "session";
  static const String columnNotes = "notes";
  static const String columnImageUrl = "image_url";

  // Nombres de columnas de Users
  static const String columnUsername = "username";
  static const String columnPassword = "password";
  static const String columnCreatedAt = "created_at";

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Almacén para compatibilidad web
  final List<Map<String, dynamic>> _webMemoryStorage = [];
  final List<Map<String, dynamic>> _webUsersStorage = [];
  int _webAutoIncrementId = 1;
  int _webUserAutoIncrementId = 1;
  bool _webInitialized = false;

  /// Cifra una contraseña usando SHA-256
  static String hashPassword(String rawPassword) {
    final bytes = utf8.encode(rawPassword);
    return sha256.convert(bytes).toString();
  }

  Future<void> _ensureWebInitialized() async {
    if (!kIsWeb || _webInitialized) return;
    _webInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar Trades web
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
            if (id is int && id > maxId) maxId = id;
          }
        }
        _webAutoIncrementId = maxId + 1;
      }

      // Cargar Usuarios web
      final String? usersJson = prefs.getString('trading_journal_web_users');
      if (usersJson != null && usersJson.isNotEmpty) {
        final List<dynamic> decodedUsers = jsonDecode(usersJson);
        _webUsersStorage.clear();
        int maxId = 0;
        for (final item in decodedUsers) {
          if (item is Map) {
            final mapItem = Map<String, dynamic>.from(item);
            _webUsersStorage.add(mapItem);
            final id = mapItem[columnId];
            if (id is int && id > maxId) maxId = id;
          }
        }
        _webUserAutoIncrementId = maxId + 1;
      }

      // Sembrar usuario admin si no existe en Web
      await _seedDefaultAdminWeb();
    } catch (e) {
      debugPrint('Error al cargar datos web persistentes: $e');
    }
  }

  Future<void> _seedDefaultAdminWeb() async {
    final exists = _webUsersStorage.any((u) => u[columnUsername] == 'admin');
    if (!exists) {
      _webUsersStorage.add({
        columnId: _webUserAutoIncrementId++,
        columnUsername: 'admin',
        columnPassword: hashPassword('admin1234'),
        columnCreatedAt: DateTime.now().toIso8601String(),
      });
      await _saveWebUsersStorage();
    }
  }

  Future<void> _saveWebStorage() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trading_journal_web_trades', jsonEncode(_webMemoryStorage));
    } catch (e) {
      debugPrint('Error al guardar trades web: $e');
    }
  }

  Future<void> _saveWebUsersStorage() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trading_journal_web_users', jsonEncode(_webUsersStorage));
    } catch (e) {
      debugPrint('Error al guardar usuarios web: $e');
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

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
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE $tableTrades ADD COLUMN $columnUserId TEXT DEFAULT "admin"');
        } catch (_) {}
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla Users
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Tabla Trades
    await db.execute('''
      CREATE TABLE $tableTrades (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId TEXT NOT NULL DEFAULT 'admin',
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

    // Insertar Usuario por defecto: admin / admin1234 (cifrado)
    await db.insert(tableUsers, {
      columnUsername: 'admin',
      columnPassword: hashPassword('admin1234'),
      columnCreatedAt: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableUsers (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUsername TEXT UNIQUE NOT NULL,
            $columnPassword TEXT NOT NULL,
            $columnCreatedAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}

      try {
        await db.execute('ALTER TABLE $tableTrades ADD COLUMN $columnUserId TEXT DEFAULT "admin"');
      } catch (_) {}

      try {
        await db.insert(tableUsers, {
          columnUsername: 'admin',
          columnPassword: hashPassword('admin1234'),
          columnCreatedAt: DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  // --- MÉTODOS DE USUARIOS ---

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      try {
        return _webUsersStorage.firstWhere(
          (u) => (u[columnUsername] as String).toLowerCase() == username.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    final db = (await database)!;
    final maps = await db.query(
      tableUsers,
      where: 'LOWER($columnUsername) = ?',
      whereArgs: [username.toLowerCase()],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      final newRow = Map<String, dynamic>.from(row);
      final id = _webUserAutoIncrementId++;
      newRow[columnId] = id;
      _webUsersStorage.add(newRow);
      await _saveWebUsersStorage();
      return id;
    }

    final db = (await database)!;
    return await db.insert(tableUsers, row);
  }

  // --- MÉTODOS DE TRADES POR USUARIO ---

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

  Future<List<Map<String, dynamic>>> getTradesByUser(String userId) async {
    if (kIsWeb) {
      await _ensureWebInitialized();
      final list = _webMemoryStorage.where((item) {
        final itemUserId = item[columnUserId]?.toString() ?? 'admin';
        return itemUserId == userId;
      }).toList();
      list.sort((a, b) => (b[columnEntryDate] as String).compareTo(a[columnEntryDate] as String));
      return list;
    }

    final db = (await database)!;
    return await db.query(
      tableTrades,
      where: '$columnUserId = ?',
      whereArgs: [userId],
      orderBy: '$columnEntryDate DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTrades() async {
    return await getTradesByUser('admin');
  }

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
