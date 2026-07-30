import 'package:flutter/foundation.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'firebase_trade_repository.dart';
import 'trade_repository_impl.dart';

/// Repositorio Híbrido que sincroniza las operaciones en almacenamiento local (SQLite/SharedPreferences)
/// y en la nube (Firebase Cloud Firestore). Si Firebase falla o está desconectado,
/// la aplicación continúa funcionando normalmente con la base de datos local.
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
  Future<List<Trade>> getTrades() async {
    if (useFirebase) {
      try {
        final remoteTrades = await firebaseRepository.getTrades();
        // Sincronizar localmente si se obtuvieron datos remotos
        for (final trade in remoteTrades) {
          try {
            await localRepository.addTrade(trade);
          } catch (_) {
            try {
              await localRepository.updateTrade(trade);
            } catch (_) {}
          }
        }
        return remoteTrades;
      } catch (e) {
        debugPrint('⚠️ Firebase no disponible o sin conexión. Usando respaldo local: $e');
      }
    }
    return await localRepository.getTrades();
  }

  @override
  Future<int> addTrade(Trade trade) async {
    // 1. Persistir localmente
    final localId = await localRepository.addTrade(trade);
    final tradeWithId = trade.id == null ? trade.copyWith(id: localId) : trade;

    // 2. Persistir en Firebase si está activo
    if (useFirebase) {
      try {
        await firebaseRepository.addTrade(tradeWithId);
      } catch (e) {
        debugPrint('⚠️ No se pudo guardar en Firebase. Guardado solo en BD local: $e');
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
        debugPrint('⚠️ No se pudo actualizar en Firebase. Actualizado solo localmente: $e');
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
        debugPrint('⚠️ No se pudo eliminar de Firebase. Eliminado solo localmente: $e');
      }
    }
    return result;
  }
}
