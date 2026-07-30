import '../entities/trade.dart';

/// Contrato del Repositorio en la Capa de Dominio.
/// Define las operaciones CRUD abstractas que la capa de presentación necesitará.
abstract class TradeRepository {
  /// Obtiene la lista completa de trades persistidos.
  Future<List<Trade>> getTrades();

  /// Agrega un nuevo trade y retorna su ID asignado en la base de datos.
  Future<int> addTrade(Trade trade);

  /// Actualiza la información de un trade existente.
  Future<int> updateTrade(Trade trade);

  /// Elimina un trade especificando su ID.
  Future<int> deleteTrade(int id);
}
