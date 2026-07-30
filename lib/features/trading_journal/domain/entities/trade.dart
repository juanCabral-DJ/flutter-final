import 'package:equatable/equatable.dart';

/// Enum que representa los resultados posibles de una operación de Trading (Solo WIN / LOSS / PENDING).
enum TradeOutcome {
  won('WIN'),
  lost('LOSS'),
  pending('PENDING');

  final String label;
  const TradeOutcome(this.label);
}

/// Enum que representa las sesiones del mercado.
enum TradingSession {
  asian('Asia', '🌏'),
  london('Londres', '🏛️'),
  newYork('Nueva York', '🗽');

  final String label;
  final String icon;
  const TradingSession(this.label, this.icon);
}

/// Entidad pura del Dominio que representa un Trade / Operación individual.
class Trade extends Equatable {
  final int? id;
  final String userId;
  final String asset;
  final String strategy;
  final DateTime entryDate;
  final double riskRewardRatio;
  final TradeOutcome outcome;
  final TradingSession session;
  final String notes;
  final String? imageUrl;

  const Trade({
    this.id,
    this.userId = 'admin',
    required this.asset,
    required this.strategy,
    required this.entryDate,
    required this.riskRewardRatio,
    required this.outcome,
    required this.session,
    this.notes = '',
    this.imageUrl,
  });

  Trade copyWith({
    int? id,
    String? userId,
    String? asset,
    String? strategy,
    DateTime? entryDate,
    double? riskRewardRatio,
    TradeOutcome? outcome,
    TradingSession? session,
    String? notes,
    String? imageUrl,
  }) {
    return Trade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      asset: asset ?? this.asset,
      strategy: strategy ?? this.strategy,
      entryDate: entryDate ?? this.entryDate,
      riskRewardRatio: riskRewardRatio ?? this.riskRewardRatio,
      outcome: outcome ?? this.outcome,
      session: session ?? this.session,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        asset,
        strategy,
        entryDate,
        riskRewardRatio,
        outcome,
        session,
        notes,
        imageUrl,
      ];
}
