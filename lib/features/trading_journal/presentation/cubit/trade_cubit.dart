import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit de Trades optimizada para deduplicación estricta de elementos y tiempo de respuesta <200ms.
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

  /// Deduplica la lista de trades por su ID único para evitar elementos repetidos en UI
  List<Trade> _deduplicate(List<Trade> trades) {
    final Map<int, Trade> map = {};
    for (final t in trades) {
      if (t.id != null) {
        map[t.id!] = t;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return list;
  }

  /// Carga inicial de trades de forma limpia.
  Future<void> loadTrades() async {
    if (_isProcessing) return;
    _isProcessing = true;
    emit(TradeLoading());
    try {
      final trades = await repository.getTrades(userId: currentUserId);
      _currentTrades = _deduplicate(trades);
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

  /// Agrega un nuevo trade obteniendo su ID real de base de datos para evitar duplicaciones en pantalla.
  Future<bool> addTrade(Trade trade) async {
    final int tempId = trade.id ?? DateTime.now().millisecondsSinceEpoch;
    final opKey = 'add_$tempId';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithId = trade.copyWith(id: tempId, userId: currentUserId);

      // Persistir de inmediato en repositorio local/híbrido
      final realId = await repository.addTrade(tradeWithId);
      final finalTrade = tradeWithId.copyWith(id: realId);

      final updatedList = List<Trade>.from(_currentTrades);
      updatedList.removeWhere((t) => t.id == tempId || t.id == realId);
      updatedList.insert(0, finalTrade);

      _currentTrades = _deduplicate(updatedList);
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
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

  /// Actualiza un trade existente sin duplicar registros.
  Future<bool> updateTrade(Trade trade) async {
    if (trade.id == null) return false;
    final opKey = 'update_${trade.id}';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithUser = trade.copyWith(userId: currentUserId);

      final updatedList = List<Trade>.from(_currentTrades);
      final index = updatedList.indexWhere((t) => t.id == trade.id);
      if (index != -1) {
        updatedList[index] = tradeWithUser;
      } else {
        updatedList.add(tradeWithUser);
      }

      await repository.updateTrade(tradeWithUser);

      _currentTrades = _deduplicate(updatedList);
      emit(TradeLoaded(
        List<Trade>.unmodifiable(_currentTrades),
        timestamp: DateTime.now(),
      ));
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

      _currentTrades = _deduplicate(updatedList);
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
