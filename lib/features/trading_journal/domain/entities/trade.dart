import 'package:equatable/equatable.dart';

/// Resultado de una operación de trading (Trade Outcome)
enum TradeOutcome {
  pending,
  won,
  lost;

  String get label {
    switch (this) {
      case TradeOutcome.pending:
        return 'Pendiente';
      case TradeOutcome.won:
        return 'Ganado (Win)';
      case TradeOutcome.lost:
        return 'Perdido (Loss)';
    }
  }
}

/// Sesión de mercado en la que se ejecutó la operación (Trading Session)
enum TradingSession {
  london,
  newYork,
  asia,
  sydney;

  String get label {
    switch (this) {
      case TradingSession.london:
        return 'Londres';
      case TradingSession.newYork:
        return 'Nueva York';
      case TradingSession.asia:
        return 'Asia / Tokio';
      case TradingSession.sydney:
        return 'Sídney';
    }
  }

  String get icon {
    switch (this) {
      case TradingSession.london:
        return '🏛️';
      case TradingSession.newYork:
        return '🏙️';
      case TradingSession.asia:
        return '🌅';
      case TradingSession.sydney:
        return '🌊';
    }
  }
}

/// Entidad pura de Dominio que representa una operación (Trade).
class Trade extends Equatable {
  final int? id;
  final String? userId;
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
    this.userId,
    required this.asset,
    required this.strategy,
    required this.entryDate,
    required this.riskRewardRatio,
    required this.outcome,
    this.session = TradingSession.newYork,
    this.notes = '',
    this.imageUrl,
  });

  /// Permite crear una copia modificada del Trade (útil para edición y asignación de usuario)
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
