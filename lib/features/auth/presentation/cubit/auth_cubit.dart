import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  /// Verifica si existe una sesión iniciada al arrancar la app.
  Future<void> checkAuthStatus() async {
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
    }
  }

  /// Inicia sesión con usuario y contraseña
  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(username, password);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Usuario o contraseña incorrectos.'));
      }
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: ${e.toString()}'));
    }
  }

  /// Registra un nuevo usuario
  Future<void> register(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(username, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Cierra la sesión activa
  Future<void> logout() async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(Unauthenticated());
  }
}
