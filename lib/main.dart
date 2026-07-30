import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/trading_journal/data/repositories/hybrid_trade_repository.dart';
import 'features/trading_journal/domain/repositories/trade_repository.dart';
import 'features/trading_journal/presentation/cubit/trade_cubit.dart';
import 'features/trading_journal/presentation/screens/main_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('⚠️ Notificación Firebase init: $e');
  }

  final TradeRepository tradeRepository = HybridTradeRepository();
  final authRepository = AuthRepositoryImpl();

  runApp(TradingJournalApp(
    tradeRepository: tradeRepository,
    authRepository: authRepository,
  ));
}

class TradingJournalApp extends StatelessWidget {
  final TradeRepository tradeRepository;
  final AuthRepositoryImpl authRepository;

  const TradingJournalApp({
    super.key,
    required this.tradeRepository,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authRepository: authRepository)..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) => TradeCubit(repository: tradeRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Trading Journal',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const AuthGuard(child: MainScreen()),
        },
        home: const RouteGuardHome(),
      ),
    );
  }
}

/// Evalúa el estado de autenticación y bloquea el acceso si no hay sesión iniciada.
class RouteGuardHome extends StatelessWidget {
  const RouteGuardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated || state is AuthError) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          context.read<TradeCubit>().setUserId(state.user.username);
          return const MainScreen();
        }

        if (state is Unauthenticated || state is AuthError) {
          return const LoginScreen();
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        );
      },
    );
  }
}

/// Guarda para rutas protegidas individuales
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    if (state is Authenticated) {
      return child;
    }
    return const LoginScreen();
  }
}
