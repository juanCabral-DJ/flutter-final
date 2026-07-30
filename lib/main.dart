import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/trading_journal/data/repositories/hybrid_trade_repository.dart';
import 'features/trading_journal/domain/repositories/trade_repository.dart';
import 'features/trading_journal/presentation/cubit/trade_cubit.dart';
import 'features/trading_journal/presentation/screens/main_screen.dart';

void main() async {
  // Asegura la inicialización de bindings para sqflite, firebase y plugins nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('⚠️ Notificación Firebase init: $e');
  }

  // Inicialización del repositorio (Firebase Firestore + SQLite local)
  final TradeRepository tradeRepository = HybridTradeRepository();

  runApp(TradingJournalApp(tradeRepository: tradeRepository));
}

class TradingJournalApp extends StatelessWidget {
  final TradeRepository tradeRepository;

  const TradingJournalApp({
    super.key,
    required this.tradeRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TradeCubit(repository: tradeRepository)..loadTrades(),
      child: MaterialApp(
        title: 'Trading Journal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
