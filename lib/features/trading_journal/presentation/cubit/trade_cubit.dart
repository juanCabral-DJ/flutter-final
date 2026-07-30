import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit encargada de manejar el estado global de Trades por usuario con llamadas explícitas a loadTrades().
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;
  String currentUserId = 'admin';
  List<Trade> _currentTrades = [];

  TradeCubit({required this.repository}) : super(TradeInitial());

  /// Configura el usuario activo y recarga los datos
  void setUserId(String userId) {
    currentUserId = userId;
    loadTrades();
  }

  /// Carga la lista completa de trades para el usuario activo (Método de refresco).
  Future<void> loadTrades() async {
    emit(TradeLoading());
    try {
      final trades = await repository.getTrades(userId: currentUserId);
      _currentTrades = List<Trade>.from(trades);
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error en loadTrades: $e');
      emit(TradeError('Error al cargar la lista de trades: ${e.toString()}'));
    }
  }

  /// Agrega un nuevo trade asignado al usuario activo e invoca explícitamente loadTrades().
  Future<void> addTrade(Trade trade) async {
    try {
      final tradeWithUser = trade.copyWith(userId: currentUserId);
      await repository.addTrade(tradeWithUser);
      // Invocar explícitamente el método de refresco (mismo del botón de recargar)
      await loadTrades();
    } catch (e) {
      debugPrint('Error en addTrade: $e');
      emit(TradeError('Error al guardar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Actualiza un trade e invoca explícitamente loadTrades().
  Future<void> updateTrade(Trade trade) async {
    try {
      final tradeWithUser = trade.copyWith(userId: currentUserId);
      await repository.updateTrade(tradeWithUser);
      // Invocar explícitamente el método de refresco (mismo del botón de recargar)
      await loadTrades();
    } catch (e) {
      debugPrint('Error en updateTrade: $e');
      emit(TradeError('Error al actualizar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Elimina un trade por ID e invoca explícitamente loadTrades().
  Future<void> deleteTrade(int id) async {
    try {
      await repository.deleteTrade(id);
      // Invocar explícitamente el método de refresco (mismo del botón de recargar)
      await loadTrades();
    } catch (e) {
      debugPrint('Error en deleteTrade: $e');
      emit(TradeError('Error al eliminar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }
}
