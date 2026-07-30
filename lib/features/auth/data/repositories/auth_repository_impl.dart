import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implementación del repositorio de autenticación con cifrado SHA-256 y persistencia de sesión.
class AuthRepositoryImpl implements AuthRepository {
  static const String _sessionKey = 'trading_journal_active_user';

  @override
  Future<User?> login(String username, String password) async {
    final map = await DatabaseHelper.instance.getUserByUsername(username);
    if (map == null) return null;

    final user = UserModel.fromMap(map);
    final inputHash = DatabaseHelper.hashPassword(password);

    if (user.passwordHash == inputHash) {
      await _saveSession(user.username);
      return user;
    }
    return null;
  }

  @override
  Future<User> register(String username, String password) async {
    final existing = await DatabaseHelper.instance.getUserByUsername(username);
    if (existing != null) {
      throw Exception('El usuario "$username" ya existe.');
    }

    final Map<String, dynamic> newUserMap = {
      DatabaseHelper.columnUsername: username.trim(),
      DatabaseHelper.columnPassword: DatabaseHelper.hashPassword(password),
      DatabaseHelper.columnCreatedAt: DateTime.now().toIso8601String(),
    };

    final id = await DatabaseHelper.instance.insertUser(newUserMap);
    newUserMap[DatabaseHelper.columnId] = id;

    final user = UserModel.fromMap(newUserMap);
    await _saveSession(user.username);
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_sessionKey);
    if (username != null && username.isNotEmpty) {
      final map = await DatabaseHelper.instance.getUserByUsername(username);
      if (map != null) {
        return UserModel.fromMap(map);
      }
    }
    return null;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, username);
  }
}
