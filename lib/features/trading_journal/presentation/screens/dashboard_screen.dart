import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/trade.dart';
import '../cubit/trade_cubit.dart';
import '../cubit/trade_state.dart';
import '../widgets/stat_card.dart';

/// Dashboard de métricas clave y gráfico comparativo de Ganados vs Perdidos.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard & Estadísticas'),
      ),
      body: BlocBuilder<TradeCubit, TradeState>(
        builder: (context, state) {
          if (state is TradeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is TradeLoaded) {
            final trades = state.trades;

            // Cálculo de estadísticas
            final totalTrades = trades.length;
            final wonTrades = trades.where((t) => t.outcome == TradeOutcome.won).length;
            final lostTrades = trades.where((t) => t.outcome == TradeOutcome.lost).length;
            final pendingTrades = trades.where((t) => t.outcome == TradeOutcome.pending).length;

            final closedTrades = wonTrades + lostTrades;
            final winRate = closedTrades > 0
                ? ((wonTrades / closedTrades) * 100)
                : 0.0;

            // R:R Promedio
            final avgRR = totalTrades > 0
                ? (trades.fold<double>(0, (sum, item) => sum + item.riskRewardRatio) / totalTrades)
                : 0.0;

            if (totalTrades == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 80,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin datos suficientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registra trades en tu historial para visualizar las métricas y gráficos estadísticos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grilla de Tarjetas Estadísticas
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatCard(
                        title: 'Total Trades',
                        value: totalTrades.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.primaryColor,
                        subtitle: '$pendingTrades pendientes',
                      ),
                      StatCard(
                        title: 'Win Rate',
                        value: '${winRate.toStringAsFixed(1)}%',
                        icon: Icons.verified_rounded,
                        color: winRate >= 50 ? AppTheme.winColor : AppTheme.lossColor,
                        subtitle: 'Trades cerrados: $closedTrades',
                      ),
                      StatCard(
                        title: 'Ganados (Wins)',
                        value: wonTrades.toString(),
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.winColor,
                      ),
                      StatCard(
                        title: 'Perdidos (Losses)',
                        value: lostTrades.toString(),
                        icon: Icons.trending_down_rounded,
                        color: AppTheme.lossColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gráfico Circular fl_chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Proporción de Operaciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Prom. R:R 1:${avgRR.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 45,
                                startDegreeOffset: -90,
                                sections: _buildPieChartSections(
                                  wonTrades: wonTrades,
                                  lostTrades: lostTrades,
                                  pendingTrades: pendingTrades,
                                  total: totalTrades,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Leyenda del gráfico
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                'Ganados',
                                AppTheme.winColor,
                                '$wonTrades',
                              ),
                              _buildLegendItem(
                                'Perdidos',
                                AppTheme.lossColor,
                                '$lostTrades',
                              ),
                              _buildLegendItem(
                                'Pendientes',
                                AppTheme.pendingColor,
                                '$pendingTrades',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Desglose por Sesión Operativa
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desglose por Sesión de Mercado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: TradingSession.values.map((session) {
                              final sessionTrades = trades.where((t) => t.session == session).toList();
                              final count = sessionTrades.length;
                              final sessionWins = sessionTrades.where((t) => t.outcome == TradeOutcome.won).length;
                              final sessionLosses = sessionTrades.where((t) => t.outcome == TradeOutcome.lost).length;
                              final sessionClosed = sessionWins + sessionLosses;
                              final sessionWinRate = sessionClosed > 0
                                  ? ((sessionWins / sessionClosed) * 100).toStringAsFixed(0)
                                  : 'N/A';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Text(
                                      session.icon,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        session.label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$count trades',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sessionClosed == 0
                                            ? AppTheme.cardColor
                                            : double.parse(sessionWinRate) >= 50
                                                ? AppTheme.winColor.withValues(alpha: 0.2)
                                                : AppTheme.lossColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sessionWinRate == 'N/A' ? 'WR: N/A' : 'WR: $sessionWinRate%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: sessionClosed == 0
                                              ? AppTheme.textSecondary
                                              : double.parse(sessionWinRate) >= 50
                                                  ? AppTheme.winColor
                                                  : AppTheme.lossColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections({
    required int wonTrades,
    required int lostTrades,
    required int pendingTrades,
    required int total,
  }) {
    final List<PieChartSectionData> sections = [];

    if (wonTrades > 0) {
      final percentage = (wonTrades / total) * 100;
      sections.add(
        PieChartSectionData(
          color: AppTheme.winColor,
          value: wonTrades.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (lostTrades > 0) {
      final percentage = (lostTrades / total) * 100;
      sections.add(
        PieChartSectionData(
          color: AppTheme.lossColor,
          value: lostTrades.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (pendingTrades > 0) {
      final percentage = (pendingTrades / total) * 100;
      sections.add(
        PieChartSectionData(
          color: AppTheme.pendingColor,
          value: pendingTrades.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLegendItem(String title, Color color, String count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
