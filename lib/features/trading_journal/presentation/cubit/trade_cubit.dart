import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit encargada de la gestión del estado de Trades con Idempotencia en operaciones CRUD.
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;
  String currentUserId = 'admin';
  List<Trade> _currentTrades = [];

  bool _isProcessing = false;
  final Set<String> _activeOperations = {};

  TradeCubit({required this.repository}) : super(TradeInitial());

  /// Configura el usuario activo e inicia la carga idempotente de sus datos.
  void setUserId(String userId) {
    if (currentUserId == userId && _currentTrades.isNotEmpty) return;
    currentUserId = userId;
    loadTrades();
  }

  /// Carga la lista completa de trades de forma limpia e idempotente.
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

  /// Agrega un nuevo trade con ID determinista previo (Idempotente) y recarga los datos.
  Future<bool> addTrade(Trade trade) async {
    final int generatedId = trade.id ?? DateTime.now().millisecondsSinceEpoch;
    final opKey = 'add_$generatedId';

    // Regla de Idempotencia: Bloquear peticiones duplicadas simultáneas
    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithId = trade.copyWith(id: generatedId, userId: currentUserId);

      // Guardado idempotente (Set/Upsert)
      await repository.addTrade(tradeWithId);

      // Invocar método explícito de recarga (loadTrades)
      await loadTrades();
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

  /// Actualiza un trade existente de forma idempotente y recarga la lista.
  Future<bool> updateTrade(Trade trade) async {
    if (trade.id == null) return false;
    final opKey = 'update_${trade.id}';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      final tradeWithUser = trade.copyWith(userId: currentUserId);
      await repository.updateTrade(tradeWithUser);

      // Invocar método explícito de recarga (loadTrades)
      await loadTrades();
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

  /// Elimina un trade por su ID de forma idempotente.
  Future<bool> deleteTrade(int id) async {
    final opKey = 'delete_$id';

    if (_activeOperations.contains(opKey)) return false;
    _activeOperations.add(opKey);

    try {
      await repository.deleteTrade(id);

      // Invocar método explícito de recarga (loadTrades)
      await loadTrades();
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
