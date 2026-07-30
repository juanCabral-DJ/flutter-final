import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit encargada de manejar el estado global de Trades con notificaciones de reconstrucción incondicionales.
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;
  List<Trade> _currentTrades = [];

  TradeCubit({required this.repository}) : super(TradeInitial());

  /// Carga la lista inicial de trades desde el repositorio.
  Future<void> loadTrades() async {
    emit(TradeLoading());
    try {
      final trades = await repository.getTrades();
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

  /// Agrega un nuevo trade, actualiza la lista inmutable en memoria y emite nuevo estado con timestamp.
  Future<void> addTrade(Trade trade) async {
    try {
      final int generatedId = await repository.addTrade(trade);
      final newTrade = trade.id == null ? trade.copyWith(id: generatedId) : trade;

      final updatedList = List<Trade>.from(_currentTrades);
      updatedList.removeWhere((t) => t.id == newTrade.id);
      updatedList.insert(0, newTrade);
      updatedList.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error en addTrade: $e');
      emit(TradeError('Error al guardar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Actualiza un trade existente, re-reemplaza el elemento en la lista inmutable y notifica a la UI.
  Future<void> updateTrade(Trade trade) async {
    try {
      await repository.updateTrade(trade);

      final updatedList = List<Trade>.from(_currentTrades);
      final index = updatedList.indexWhere((t) => t.id == trade.id);
      if (index != -1) {
        updatedList[index] = trade;
      } else {
        updatedList.add(trade);
      }
      updatedList.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error en updateTrade: $e');
      emit(TradeError('Error al actualizar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Elimina un trade por ID de la lista inmutable y notifica inmediatamente.
  Future<void> deleteTrade(int id) async {
    try {
      await repository.deleteTrade(id);

      final updatedList = List<Trade>.from(_currentTrades);
      updatedList.removeWhere((t) => t.id == id);

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error en deleteTrade: $e');
      emit(TradeError('Error al eliminar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }
}
