import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit encargada de manejar la lógica de estado y operaciones CRUD con reactividad instantánea.
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;
  List<Trade> _currentTrades = [];

  TradeCubit({required this.repository}) : super(TradeInitial());

  /// Carga la lista inicial de trades desde el repositorio.
  Future<void> loadTrades() async {
    emit(TradeLoading());
    try {
      _currentTrades = await repository.getTrades();
      emit(TradeLoaded(List<Trade>.from(_currentTrades)));
    } catch (e) {
      emit(TradeError('Error al cargar la lista de trades: ${e.toString()}'));
    }
  }

  /// Agrega un nuevo trade, actualiza el estado en memoria al instante y persiste en BD.
  Future<void> addTrade(Trade trade) async {
    try {
      final int generatedId = await repository.addTrade(trade);
      final newTrade = trade.id == null ? trade.copyWith(id: generatedId) : trade;

      _currentTrades.removeWhere((t) => t.id == newTrade.id);
      _currentTrades.insert(0, newTrade);
      _currentTrades.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      emit(TradeLoaded(List<Trade>.from(_currentTrades)));
    } catch (e) {
      emit(TradeError('Error al guardar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Actualiza un trade existente en memoria al instante y en la BD.
  Future<void> updateTrade(Trade trade) async {
    try {
      await repository.updateTrade(trade);

      final index = _currentTrades.indexWhere((t) => t.id == trade.id);
      if (index != -1) {
        _currentTrades[index] = trade;
      } else {
        _currentTrades.add(trade);
      }
      _currentTrades.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      emit(TradeLoaded(List<Trade>.from(_currentTrades)));
    } catch (e) {
      emit(TradeError('Error al actualizar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }

  /// Elimina un trade por su ID en memoria al instante y en la BD.
  Future<void> deleteTrade(int id) async {
    try {
      await repository.deleteTrade(id);

      _currentTrades.removeWhere((t) => t.id == id);
      emit(TradeLoaded(List<Trade>.from(_currentTrades)));
    } catch (e) {
      emit(TradeError('Error al eliminar el trade: ${e.toString()}'));
      await loadTrades();
    }
  }
}
