import '../../domain/entities/trade.dart';

/// Modelo de datos que hereda de la entidad [Trade] y añade serialización/deserialización
/// para interactuar con SQLite y Firestore.
class TradeModel extends Trade {
  const TradeModel({
    super.id,
    super.userId = 'admin',
    required super.asset,
    required super.strategy,
    required super.entryDate,
    required super.riskRewardRatio,
    required super.outcome,
    required super.session,
    super.notes = '',
    super.imageUrl,
  });

  /// Convierte un Map proveniente de la BD a una instancia de [TradeModel].
  factory TradeModel.fromMap(Map<String, dynamic> map) {
    return TradeModel(
      id: map['id'] as int?,
      userId: map['user_id']?.toString() ?? 'admin',
      asset: map['asset'] as String,
      strategy: map['strategy'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      riskRewardRatio: (map['risk_reward_ratio'] as num).toDouble(),
      outcome: TradeOutcome.values.firstWhere(
        (e) => e.name == map['outcome'],
        orElse: () => TradeOutcome.pending,
      ),
      session: TradingSession.values.firstWhere(
        (e) => e.name == map['session'],
        orElse: () => TradingSession.newYork,
      ),
      notes: (map['notes'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
    );
  }

  /// Convierte la instancia de [TradeModel] a un Map compatible con SQLite y Firestore.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'asset': asset,
      'strategy': strategy,
      'entry_date': entryDate.toIso8601String(),
      'risk_reward_ratio': riskRewardRatio,
      'outcome': outcome.name,
      'session': session.name,
      'notes': notes,
      'image_url': imageUrl,
      'user_id': userId,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Factory helper para convertir una entidad de dominio [Trade] a [TradeModel].
  factory TradeModel.fromEntity(Trade trade) {
    return TradeModel(
      id: trade.id,
      userId: trade.userId,
      asset: trade.asset,
      strategy: trade.strategy,
      entryDate: trade.entryDate,
      riskRewardRatio: trade.riskRewardRatio,
      outcome: trade.outcome,
      session: trade.session,
      notes: trade.notes,
      imageUrl: trade.imageUrl,
    );
  }
}
