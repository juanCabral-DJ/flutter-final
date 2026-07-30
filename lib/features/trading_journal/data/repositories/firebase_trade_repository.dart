import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import '../models/trade_model.dart';

/// Implementación concreta de [TradeRepository] para persistencia en Firebase Cloud Firestore.
class FirebaseTradeRepository implements TradeRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'trades';

  FirebaseTradeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tradesCollection =>
      _firestore.collection(_collectionName);

  @override
  Future<List<Trade>> getTrades() async {
    try {
      final snapshot = await _tradesCollection
          .orderBy('entry_date', descending: true)
          .get()
          .timeout(const Duration(seconds: 4));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id') || data['id'] == null) {
          data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        }
        return TradeModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener trades de Firebase: $e');
      rethrow;
    }
  }

  @override
  Future<int> addTrade(Trade trade) async {
    try {
      final int generatedId = trade.id ?? DateTime.now().millisecondsSinceEpoch;
      final tradeWithId = trade.copyWith(id: generatedId);
      final model = TradeModel.fromEntity(tradeWithId);

      final mapData = model.toMap();
      await _tradesCollection.doc(generatedId.toString()).set(mapData);
      return generatedId;
    } catch (e) {
      debugPrint('Error al agregar trade a Firebase: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateTrade(Trade trade) async {
    try {
      if (trade.id == null) {
        throw ArgumentError('El ID del trade es obligatorio para actualización.');
      }
      final model = TradeModel.fromEntity(trade);
      await _tradesCollection.doc(trade.id.toString()).set(
            model.toMap(),
            SetOptions(merge: true),
          );
      return 1;
    } catch (e) {
      debugPrint('Error al actualizar trade en Firebase: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteTrade(int id) async {
    try {
      await _tradesCollection.doc(id.toString()).delete();
      return 1;
    } catch (e) {
      debugPrint('Error al eliminar trade en Firebase: $e');
      rethrow;
    }
  }

  /// Transmite la lista de trades en tiempo real desde Firebase Firestore.
  Stream<List<Trade>> watchTrades() {
    return _tradesCollection
        .orderBy('entry_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id') || data['id'] == null) {
          data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        }
        return TradeModel.fromMap(data);
      }).toList();
    });
  }
}
