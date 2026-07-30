import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/trade.dart';
import '../cubit/trade_cubit.dart';
import '../cubit/trade_state.dart';
import '../widgets/trade_card.dart';
import 'add_edit_trade_screen.dart';

/// Pantalla que muestra el historial completo de Trades en una lista deslizable.
class TradeHistoryScreen extends StatelessWidget {
  const TradeHistoryScreen({super.key});

  void _navigateToForm(BuildContext context, [Trade? tradeToEdit]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TradeCubit>(),
          child: AddEditTradeScreen(tradeToEdit: tradeToEdit),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Eliminar Trade'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la operación de ${trade.asset}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lossColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (trade.id != null) {
                await context.read<TradeCubit>().deleteTrade(trade.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trade ${trade.asset} eliminado'),
                      backgroundColor: AppTheme.cardColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TradeCubit>().loadTrades(),
            tooltip: 'Recargar listado',
          ),
        ],
      ),
      body: BlocConsumer<TradeCubit, TradeState>(
        listener: (context, state) {
          if (state is TradeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.lossColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TradeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is TradeLoaded) {
            final trades = state.trades;

            if (trades.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined_rounded,
                        size: 80,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay trades registrados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toca el botón (+) para agregar tu primera operación de trading.',
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

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades[index];
                return Dismissible(
                  key: Key('trade_${trade.id ?? index}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lossColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    _confirmDelete(context, trade);
                    return false; // El diálogo manejará la eliminación si confirma
                  },
                  child: TradeCard(
                    trade: trade,
                    onTap: () => _navigateToForm(context, trade),
                    onDelete: () => _confirmDelete(context, trade),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Trade'),
      ),
    );
  }
}
