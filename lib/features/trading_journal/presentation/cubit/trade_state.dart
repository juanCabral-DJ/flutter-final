import 'package:equatable/equatable.dart';
import '../../domain/entities/trade.dart';

/// Estados posibles de la vista de Trading Journal manejados por el Cubit.
abstract class TradeState extends Equatable {
  const TradeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial previo a cualquier carga.
class TradeInitial extends TradeState {}

/// Estado indicando que se están cargando o procesando operaciones en la BD.
class TradeLoading extends TradeState {}

/// Estado emitido cuando los trades han sido leídos exitosamente de la BD.
/// Se incluye un timestamp para garantizar que Flutter BLoC re-renderice siempre la UI.
class TradeLoaded extends TradeState {
  final List<Trade> trades;
  final DateTime timestamp;

  TradeLoaded(this.trades, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [trades, timestamp];
}

/// Estado emitido cuando ocurre algún error en las operaciones de BD.
class TradeError extends TradeState {
  final String message;

  const TradeError(this.message);

  @override
  List<Object?> get props => [message];
}
