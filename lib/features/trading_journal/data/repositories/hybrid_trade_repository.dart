import 'package:flutter/foundation.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'firebase_trade_repository.dart';
import 'trade_repository_impl.dart';

/// Repositorio Híbrido que filtra las operaciones locales y en Firebase por usuario.
class HybridTradeRepository implements TradeRepository {
  final TradeRepositoryImpl localRepository;
  final FirebaseTradeRepository firebaseRepository;
  bool useFirebase;

  HybridTradeRepository({
    TradeRepositoryImpl? localRepository,
    FirebaseTradeRepository? firebaseRepository,
    this.useFirebase = true,
  })  : localRepository = localRepository ?? TradeRepositoryImpl(),
        firebaseRepository = firebaseRepository ?? FirebaseTradeRepository();

  @override
  Future<List<Trade>> getTrades({String? userId}) async {
    final targetUserId = userId ?? 'admin';
    final localTrades = await localRepository.getTrades(userId: targetUserId);

    if (useFirebase) {
      try {
        final remoteTrades = await firebaseRepository.getTrades(userId: targetUserId);
        if (remoteTrades.isNotEmpty) {
          final Map<int, Trade> tradeMap = {};
          for (final t in localTrades) {
            if (t.id != null) tradeMap[t.id!] = t;
          }
          for (final t in remoteTrades) {
            if (t.id != null) tradeMap[t.id!] = t;
          }
          final merged = tradeMap.values.toList();
          merged.sort((a, b) => b.entryDate.compareTo(a.entryDate));
          return merged;
        }
      } catch (e) {
        debugPrint('⚠️ Firebase no disponible. Usando datos locales para $targetUserId: $e');
      }
    }

    return localTrades;
  }

  @override
  Future<int> addTrade(Trade trade) async {
    final localId = await localRepository.addTrade(trade);
    final tradeWithId = trade.id == null ? trade.copyWith(id: localId) : trade;

    if (useFirebase) {
      try {
        await firebaseRepository.addTrade(tradeWithId);
      } catch (e) {
        debugPrint('⚠️ No se pudo guardar en Firebase: $e');
      }
    }
    return localId;
  }

  @override
  Future<int> updateTrade(Trade trade) async {
    final result = await localRepository.updateTrade(trade);

    if (useFirebase) {
      try {
        await firebaseRepository.updateTrade(trade);
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar en Firebase: $e');
      }
    }
    return result;
  }

  @override
  Future<int> deleteTrade(int id) async {
    final result = await localRepository.deleteTrade(id);

    if (useFirebase) {
      try {
        await firebaseRepository.deleteTrade(id);
      } catch (e) {
        debugPrint('⚠️ No se pudo eliminar de Firebase: $e');
      }
    }
    return result;
  }
}
