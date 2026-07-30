import '../entities/trade.dart';

/// Contrato del Repositorio de Trades en la Capa de Dominio.
abstract class TradeRepository {
  /// Obtiene la lista de trades pertenecientes a un usuario específico.
  Future<List<Trade>> getTrades({String? userId});

  /// Agrega un nuevo trade asignado al usuario.
  Future<int> addTrade(Trade trade);

  /// Actualiza un trade existente.
  Future<int> updateTrade(Trade trade);

  /// Elimina un trade por su ID.
  Future<int> deleteTrade(int id);
}
