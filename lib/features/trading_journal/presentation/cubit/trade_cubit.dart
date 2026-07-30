import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit de Trades optimizada para tiempo de respuesta < 200ms con actualización optimista e idempotencia.
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;
  String currentUserId = 'admin';
  List<Trade> _currentTrades = [];

  bool _isProcessing = false;
  final Set<String> _activeOperations = {};

  TradeCubit({required this.repository}) : super(TradeInitial());

  void setUserId(String userId) {
    if (currentUserId == userId && _currentTrades.isNotEmpty) return;
    currentUserId = userId;
    loadTrades();
  }

  /// Carga inicial de trades de forma limpia.
  Future<void> loadTrades() async {
    if (_isProcessing) return;
    _isProcessing = true;
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
    } finally {
      _isProcessing = false;
    }
  }

  /// Agrega un nuevo trade con tiempo de respuesta < 200ms (optimista) e idempotente.
  Future<bool> addTrade(Trade trade) async {
    final int generatedId = trade.id ?? DateTime.now().millisecondsSinceEpoch;
    final opKey = 'add_$generatedId';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithId = trade.copyWith(id: generatedId, userId: currentUserId);

      // Actualización optimista instantánea en memoria (0-5 ms)
      final updatedList = List<Trade>.from(_currentTrades);
      updatedList.removeWhere((t) => t.id == generatedId);
      updatedList.insert(0, tradeWithId);
      updatedList.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));

      // Persistir asíncronamente en segundo plano
      unawaited(repository.addTrade(tradeWithId));
      return true;
    } catch (e) {
      debugPrint('Error en addTrade: $e');
      emit(TradeError('Error al guardar el trade: ${e.toString()}'));
      await loadTrades();
      return false;
    } finally {
      _activeOperations.remove(opKey);
    }
  }

  /// Actualiza un trade existente con tiempo de respuesta < 200ms e idempotente.
  Future<bool> updateTrade(Trade trade) async {
    if (trade.id == null) return false;
    final opKey = 'update_${trade.id}';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithUser = trade.copyWith(userId: currentUserId);

      // Actualización optimista instantánea en memoria (0-5 ms)
      final updatedList = List<Trade>.from(_currentTrades);
      final index = updatedList.indexWhere((t) => t.id == trade.id);
      if (index != -1) {
        updatedList[index] = tradeWithUser;
      } else {
        updatedList.add(tradeWithUser);
      }
      updatedList.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));

      // Persistir asíncronamente en segundo plano
      unawaited(repository.updateTrade(tradeWithUser));
      return true;
    } catch (e) {
      debugPrint('Error en updateTrade: $e');
      emit(TradeError('Error al actualizar el trade: ${e.toString()}'));
      await loadTrades();
      return false;
    } finally {
      _activeOperations.remove(opKey);
    }
  }

  /// Elimina un trade por su ID notificando éxito o error.
  Future<bool> deleteTrade(int id) async {
    final opKey = 'delete_$id';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final updatedList = List<Trade>.from(_currentTrades);
      updatedList.removeWhere((t) => t.id == id);

      _currentTrades = updatedList;
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));

      await repository.deleteTrade(id);
      return true;
    } catch (e) {
      debugPrint('Error en deleteTrade: $e');
      emit(TradeError('Error al eliminar el trade: ${e.toString()}'));
      await loadTrades();
      return false;
    } finally {
      _activeOperations.remove(opKey);
    }
  }
}
