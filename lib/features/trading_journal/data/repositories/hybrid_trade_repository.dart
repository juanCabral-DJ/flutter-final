import 'package:flutter/foundation.dart';
import '../../../../firebase_options.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'firebase_trade_repository.dart';
import 'trade_repository_impl.dart';

/// Repositorio Híbrido que detecta inteligentemente si Firebase posee credenciales reales
/// o si debe operar directamente en almacenamiento local sin retardos ni TimeoutExceptions.
class HybridTradeRepository implements TradeRepository {
  final TradeRepositoryImpl localRepository;
  final FirebaseTradeRepository firebaseRepository;
  bool useFirebase;
  static bool _firebaseAvailable = true;

  HybridTradeRepository({
    TradeRepositoryImpl? localRepository,
    FirebaseTradeRepository? firebaseRepository,
    this.useFirebase = true,
  })  : localRepository = localRepository ?? TradeRepositoryImpl(),
        firebaseRepository = firebaseRepository ?? FirebaseTradeRepository() {
    // Si las opciones tienen claves de demostración/placeholder, desactivar Firebase para evitar timeouts
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      if (apiKey.contains('DemoKey')) {
        _firebaseAvailable = false;
        debugPrint('ℹ️ Modo local activo: Claves de Firebase en modo demostración/offline.');
      }
    } catch (_) {
      _firebaseAvailable = false;
    }
  }

  bool get _canUseFirebase => useFirebase && _firebaseAvailable;

  @override
  Future<List<Trade>> getTrades({String? userId}) async {
    final targetUserId = userId ?? 'admin';
    final localTrades = await localRepository.getTrades(userId: targetUserId);

    if (_canUseFirebase) {
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
        _firebaseAvailable = false; // Desactivar si falla o da timeout para no ralentizar consultas futuras
        debugPrint('⚠️ Firebase no disponible. Conmutado a almacenamiento local con 0ms de retardo.');
      }
    }

    return localTrades;
  }

  @override
  Future<int> addTrade(Trade trade) async {
    final localId = await localRepository.addTrade(trade);
    final tradeWithId = trade.id == null ? trade.copyWith(id: localId) : trade;

    if (_canUseFirebase) {
      try {
        await firebaseRepository.addTrade(tradeWithId);
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('⚠️ No se pudo guardar en Firebase. Guardado localmente.');
      }
    }
    return localId;
  }

  @override
  Future<int> updateTrade(Trade trade) async {
    final result = await localRepository.updateTrade(trade);

    if (_canUseFirebase) {
      try {
        await firebaseRepository.updateTrade(trade);
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('⚠️ No se pudo actualizar en Firebase. Actualizado localmente.');
      }
    }
    return result;
  }

  @override
  Future<int> deleteTrade(int id) async {
    final result = await localRepository.deleteTrade(id);

    if (_canUseFirebase) {
      try {
        await firebaseRepository.deleteTrade(id);
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('⚠️ No se pudo eliminar de Firebase. Eliminado localmente.');
      }
    }
    return result;
  }
}
