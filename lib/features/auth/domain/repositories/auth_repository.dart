import '../entities/user.dart';

/// Contrato del Repositorio de Autenticación.
abstract class AuthRepository {
  /// Inicia sesión verificando credenciales con la contraseña cifrada.
  Future<User?> login(String username, String password);

  /// Registra un nuevo usuario cifrando su contraseña.
  Future<User> register(String username, String password);

  /// Obtiene el usuario actualmente autenticado (sesión activa).
  Future<User?> getCurrentUser();

  /// Cierra la sesión activa.
  Future<void> logout();
}
