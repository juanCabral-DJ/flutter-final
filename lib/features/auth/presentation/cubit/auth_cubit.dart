import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit de Autenticación con Idempotencia para evitar peticiones duplicadas o innecesarias.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  bool _isAuthenticating = false;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  /// Verifica el estado de autenticación al iniciar la app.
  Future<void> checkAuthStatus() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Inicia sesión de forma idempotente evitando múltiples llamadas simultáneas.
  Future<void> login(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    // Regla de Idempotencia: Omitir si hay autenticación en curso o si ya está autenticado con el mismo usuario.
    if (_isAuthenticating) return;
    if (state is Authenticated &&
        (state as Authenticated).user.username.toLowerCase() == cleanUsername.toLowerCase()) {
      return;
    }

    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      final user = await authRepository.login(cleanUsername, cleanPassword);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Usuario o contraseña incorrectos.'));
      }
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: ${e.toString()}'));
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Registra un nuevo usuario de forma idempotente.
  Future<void> register(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    // Regla de Idempotencia
    if (_isAuthenticating) return;
    if (state is Authenticated &&
        (state as Authenticated).user.username.toLowerCase() == cleanUsername.toLowerCase()) {
      return;
    }

    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      final user = await authRepository.register(cleanUsername, cleanPassword);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Cierra la sesión activa.
  Future<void> logout() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } finally {
      _isAuthenticating = false;
    }
  }
}
