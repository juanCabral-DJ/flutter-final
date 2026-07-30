import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../trading_journal/presentation/cubit/trade_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla de Autenticación con redirección automática tras inicio de sesión exitoso.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Método específico para procesar el Inicio de Sesión
  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    context.read<AuthCubit>().login(username, password);
  }

  /// Método específico para procesar el Registro de Usuario
  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    context.read<AuthCubit>().register(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                // Configurar usuario activo en TradeCubit y redirigir inmediatamente a MainScreen
                context.read<TradeCubit>().setUserId(state.user.username);
                navigatorKey.currentState?.pushNamedAndRemoveUntil('/main', (route) => false);
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.lossColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícono y Título
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.candlestick_chart_rounded,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Trading Journal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRegisterMode
                                ? 'Crea una cuenta para aislar tus operaciones'
                                : 'Ingresa tus credenciales para acceder',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Campo Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              hintText: 'Ingresa tu nombre de usuario',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre de usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña (Cifrada)',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (value.trim().length < 4) {
                                return 'La contraseña debe tener al menos 4 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Botón principal de Iniciar Sesión o Registro
                          if (!_isRegisterMode) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _handleLogin,
                                icon: const Icon(Icons.login_rounded),
                                label: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isRegisterMode = true;
                                      });
                                    },
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Crear Nueva Cuenta'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                side: const BorderSide(color: AppTheme.primaryColor),
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _handleRegister,
                                icon: const Icon(Icons.how_to_reg_rounded),
                                label: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Registrar Usuario',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.winColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isRegisterMode = false;
                                      });
                                    },
                              child: const Text(
                                '¿Ya tienes cuenta? Iniciar Sesión',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
