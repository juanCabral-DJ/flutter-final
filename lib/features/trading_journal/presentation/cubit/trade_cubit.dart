import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'trade_state.dart';

/// Cubit encargada de manejar la lógica de estado y operaciones CRUD de los Trades.
class TradeCubit extends Cubit<TradeState> {
  final TradeRepository repository;

  TradeCubit({required this.repository}) : super(TradeInitial());

  /// Carga todas las operaciones almacenadas en la base de datos local.
  Future<void> loadTrades() async {
    emit(TradeLoading());
    try {
      final trades = await repository.getTrades();
      emit(TradeLoaded(trades));
    } catch (e) {
      emit(TradeError('Error al cargar la lista de trades: ${e.toString()}'));
    }
  }

  /// Agrega un nuevo trade a la BD y recarga la lista.
  Future<void> addTrade(Trade trade) async {
    try {
      await repository.addTrade(trade);
      await loadTrades();
    } catch (e) {
      emit(TradeError('Error al guardar el trade: ${e.toString()}'));
    }
  }

  /// Actualiza un trade existente en la BD y recarga la lista.
  Future<void> updateTrade(Trade trade) async {
    try {
      await repository.updateTrade(trade);
      await loadTrades();
    } catch (e) {
      emit(TradeError('Error al actualizar el trade: ${e.toString()}'));
    }
  }

  /// Elimina un trade por su ID y recarga la lista.
  Future<void> deleteTrade(int id) async {
    try {
      await repository.deleteTrade(id);
      await loadTrades();
    } catch (e) {
      emit(TradeError('Error al eliminar el trade: ${e.toString()}'));
    }
  }
}
