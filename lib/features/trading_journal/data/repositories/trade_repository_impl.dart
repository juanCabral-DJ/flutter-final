import '../../../../core/database/database_helper.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import '../models/trade_model.dart';

/// Implementación concreta de [TradeRepository] que utiliza [DatabaseHelper] con filtrado por usuario.
class TradeRepositoryImpl implements TradeRepository {
  final DatabaseHelper dbHelper;

  TradeRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Trade>> getTrades({String? userId}) async {
    final targetUserId = userId ?? 'admin';
    final List<Map<String, dynamic>> maps = await dbHelper.getTradesByUser(targetUserId);
    return maps.map((map) => TradeModel.fromMap(map)).toList();
  }

  @override
  Future<int> addTrade(Trade trade) async {
    final model = TradeModel.fromEntity(trade);
    return await dbHelper.insertTrade(model.toMap());
  }

  @override
  Future<int> updateTrade(Trade trade) async {
    final model = TradeModel.fromEntity(trade);
    return await dbHelper.updateTrade(model.toMap());
  }

  @override
  Future<int> deleteTrade(int id) async {
    return await dbHelper.deleteTrade(id);
  }
}
