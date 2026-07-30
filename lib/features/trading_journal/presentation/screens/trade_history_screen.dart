import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/trade.dart';
import '../cubit/trade_cubit.dart';
import '../cubit/trade_state.dart';
import '../widgets/trade_card.dart';
import 'add_edit_trade_screen.dart';

/// Pantalla que muestra el historial completo de Trades con filtrado interactivo por activo, estado, sesión y fecha.
class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  TradeOutcome? _selectedOutcomeFilter;
  TradingSession? _selectedSessionFilter;
  DateTime? _selectedDateFilter;
  bool _showFilterPanel = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_selectedOutcomeFilter != null) count++;
    if (_selectedSessionFilter != null) count++;
    if (_selectedDateFilter != null) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedOutcomeFilter = null;
      _selectedSessionFilter = null;
      _selectedDateFilter = null;
    });
  }

  List<Trade> _applyFilters(List<Trade> allTrades) {
    final query = _searchController.text.trim().toLowerCase();

    return allTrades.where((trade) {
      // 1. Filtro por Símbolo / Activo o Estrategia
      if (query.isNotEmpty) {
        final assetMatch = trade.asset.toLowerCase().contains(query);
        final strategyMatch = trade.strategy.toLowerCase().contains(query);
        if (!assetMatch && !strategyMatch) return false;
      }

      // 2. Filtro por Estado (Outcome)
      if (_selectedOutcomeFilter != null && trade.outcome != _selectedOutcomeFilter) {
        return false;
      }

      // 3. Filtro por Sesión (Session)
      if (_selectedSessionFilter != null && trade.session != _selectedSessionFilter) {
        return false;
      }

      // 4. Filtro por Fecha
      if (_selectedDateFilter != null) {
        final sameYear = trade.entryDate.year == _selectedDateFilter!.year;
        final sameMonth = trade.entryDate.month == _selectedDateFilter!.month;
        final sameDay = trade.entryDate.day == _selectedDateFilter!.day;
        if (!sameYear || !sameMonth || !sameDay) return false;
      }

      return true;
    }).toList();
  }

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
                final success = await context.read<TradeCubit>().deleteTrade(trade.id!);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Operación de ${trade.asset} eliminada con éxito'),
                        backgroundColor: AppTheme.winColor,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo eliminar la operación de ${trade.asset}'),
                        backgroundColor: AppTheme.lossColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateFilter() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateFilter = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = _activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Trades'),
        actions: [
          // Botón para desplegar / ocultar panel de filtros avanzados
          IconButton(
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text(
                '$activeFilters',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                _showFilterPanel ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                color: activeFilters > 0 ? AppTheme.primaryColor : null,
              ),
            ),
            onPressed: () {
              setState(() {
                _showFilterPanel = !_showFilterPanel;
              });
            },
            tooltip: 'Filtros avanzados',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TradeCubit>().loadTrades(),
            tooltip: 'Recargar listado',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de Búsqueda por Símbolo / Activo y Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                // Campo de Búsqueda rápida por Símbolo
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por Símbolo o Estrategia (Ej: EURUSD, MNQ)',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Panel Plegable de Filtros Avanzados (Estado, Sesión, Fecha)
                if (_showFilterPanel) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.cardColor, height: 1),
                  const SizedBox(height: 12),

                  // Filtro por Estado (Outcome)
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Estado:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Todos'),
                                selected: _selectedOutcomeFilter == null,
                                onSelected: (_) => setState(() => _selectedOutcomeFilter = null),
                                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                label: const Text('WIN'),
                                selected: _selectedOutcomeFilter == TradeOutcome.won,
                                selectedColor: AppTheme.winColor.withValues(alpha: 0.3),
                                onSelected: (_) => setState(() {
                                  _selectedOutcomeFilter =
                                      _selectedOutcomeFilter == TradeOutcome.won
                                          ? null
                                          : TradeOutcome.won;
                                }),
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                label: const Text('LOSS'),
                                selected: _selectedOutcomeFilter == TradeOutcome.lost,
                                selectedColor: AppTheme.lossColor.withValues(alpha: 0.3),
                                onSelected: (_) => setState(() {
                                  _selectedOutcomeFilter =
                                      _selectedOutcomeFilter == TradeOutcome.lost
                                          ? null
                                          : TradeOutcome.lost;
                                }),
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                label: const Text('PENDING'),
                                selected: _selectedOutcomeFilter == TradeOutcome.pending,
                                selectedColor: AppTheme.pendingColor.withValues(alpha: 0.3),
                                onSelected: (_) => setState(() {
                                  _selectedOutcomeFilter =
                                      _selectedOutcomeFilter == TradeOutcome.pending
                                          ? null
                                          : TradeOutcome.pending;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filtro por Sesión de Mercado
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Sesión:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Todas'),
                                selected: _selectedSessionFilter == null,
                                onSelected: (_) => setState(() => _selectedSessionFilter = null),
                                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                              ),
                              ...TradingSession.values.map((session) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: ChoiceChip(
                                    label: Text('${session.icon} ${session.label}'),
                                    selected: _selectedSessionFilter == session,
                                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    onSelected: (_) => setState(() {
                                      _selectedSessionFilter =
                                          _selectedSessionFilter == session ? null : session;
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filtro por Fecha y Botón Limpiar
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Fecha:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _pickDateFilter,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          _selectedDateFilter == null
                              ? 'Cualquier fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedDateFilter!),
                          style: TextStyle(
                            color: _selectedDateFilter == null
                                ? AppTheme.textSecondary
                                : AppTheme.primaryColor,
                            fontWeight: _selectedDateFilter == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectedDateFilter != null)
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          onPressed: () => setState(() => _selectedDateFilter = null),
                          tooltip: 'Quitar fecha',
                        ),
                      const Spacer(),
                      if (activeFilters > 0)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                          label: const Text('Limpiar Filtros'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.lossColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Contenido de la Lista de Trades Filtrada
          Expanded(
            child: BlocConsumer<TradeCubit, TradeState>(
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
                  final filteredTrades = _applyFilters(state.trades);

                  if (filteredTrades.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activeFilters > 0
                                  ? Icons.filter_alt_off_rounded
                                  : Icons.insert_chart_outlined_rounded,
                              size: 72,
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              activeFilters > 0
                                  ? 'No hay trades que coincidan con los filtros'
                                  : 'No hay trades registrados',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeFilters > 0
                                  ? 'Intenta cambiar o limpiar los filtros de búsqueda.'
                                  : 'Toca el botón (+) para agregar tu primera operación de trading.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (activeFilters > 0) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Limpiar Filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: filteredTrades.length,
                    itemBuilder: (context, index) {
                      final trade = filteredTrades[index];
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
                          return false;
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Trade'),
      ),
    );
  }
}
