import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../domain/entities/trade.dart';
import '../cubit/trade_cubit.dart';

/// Formulario para Crear o Editar un Trade existente.
class AddEditTradeScreen extends StatefulWidget {
  final Trade? tradeToEdit;

  const AddEditTradeScreen({super.key, this.tradeToEdit});

  @override
  State<AddEditTradeScreen> createState() => _AddEditTradeScreenState();
}

class _AddEditTradeScreenState extends State<AddEditTradeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _assetController;
  late TextEditingController _strategyController;
  late TextEditingController _riskRewardController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TradeOutcome _selectedOutcome;
  late TradingSession _selectedSession;
  String? _imageUrl;

  bool get _isEditing => widget.tradeToEdit != null;

  @override
  void initState() {
    super.initState();
    final trade = widget.tradeToEdit;
    _assetController = TextEditingController(text: trade?.asset ?? '');
    _strategyController = TextEditingController(text: trade?.strategy ?? '');
    _riskRewardController = TextEditingController(
      text: trade?.riskRewardRatio.toString() ?? '2.0',
    );
    _notesController = TextEditingController(text: trade?.notes ?? '');
    _selectedDate = trade?.entryDate ?? DateTime.now();
    _selectedOutcome = trade?.outcome ?? TradeOutcome.pending;
    _selectedSession = trade?.session ?? TradingSession.newYork;
    _imageUrl = trade?.imageUrl;
  }

  @override
  void dispose() {
    _assetController.dispose();
    _strategyController.dispose();
    _riskRewardController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final base64Image = await pickImageCrossPlatform();
      if (base64Image != null && base64Image.isNotEmpty) {
        setState(() {
          _imageUrl = base64Image;
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.lossColor,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedRR = double.tryParse(_riskRewardController.text.trim()) ?? 1.0;

    final trade = Trade(
      id: widget.tradeToEdit?.id,
      asset: _assetController.text.trim().toUpperCase(),
      strategy: _strategyController.text.trim(),
      entryDate: _selectedDate,
      riskRewardRatio: parsedRR,
      outcome: _selectedOutcome,
      session: _selectedSession,
      notes: _notesController.text.trim(),
      imageUrl: _imageUrl,
    );

    final cubit = context.read<TradeCubit>();
    final bool success;
    if (_isEditing) {
      success = await cubit.updateTrade(trade);
    } else {
      success = await cubit.addTrade(trade);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Trade actualizado con éxito' : 'Nuevo trade registrado con éxito',
          ),
          backgroundColor: AppTheme.winColor,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Trade' : 'Nuevo Trade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título decorativo
              Text(
                _isEditing
                    ? 'Modifica los parámetros de la operación'
                    : 'Ingresa los detalles de la nueva operación',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Campo: Activo
              TextFormField(
                controller: _assetController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Activo / Par',
                  hintText: 'Ej: MNQ, EURUSD, BTCUSD',
                  prefixIcon: Icon(Icons.show_chart_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del activo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Estrategia
              TextFormField(
                controller: _strategyController,
                decoration: const InputDecoration(
                  labelText: 'Estrategia',
                  hintText: 'Ej: SMC, ICT, Breakout, Scalping',
                  prefixIcon: Icon(Icons.psychology_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la estrategia utilizada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Risk / Reward Ratio (R:R)
              TextFormField(
                controller: _riskRewardController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ratio Riesgo : Beneficio (R:R)',
                  hintText: 'Ej: 2.5 (representa 1:2.5)',
                  prefixIcon: Icon(Icons.balance_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el R:R';
                  }
                  final number = double.tryParse(value.trim());
                  if (number == null || number <= 0) {
                    return 'Ingresa un número válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Selector de Sesión de Mercado
              const Text(
                'Sesión Operativa (Mercado)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TradingSession.values.map((session) {
                  final isSelected = _selectedSession == session;
                  return ChoiceChip(
                    label: Text('${session.icon} ${session.label}'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    backgroundColor: AppTheme.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedSession = session;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Campo: Notas / Observaciones
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas / Observaciones',
                  hintText: 'Ej: Entrada en FVG tras toma de liquidez en Asia. Emociones estables.',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección: Captura de Gráfico / Imagen
              const Text(
                'Captura de Gráfico / Setup (Imagen)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: AppTheme.cardColor,
                        child: _buildImagePreview(_imageUrl!),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.7),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        onPressed: _removeImage,
                        tooltip: 'Eliminar imagen',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: Text(_imageUrl == null ? 'Adjuntar Captura del Chart' : 'Cambiar Imagen'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Fecha
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de Entrada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selector de Resultado (SegmentedButton)
              const Text(
                'Resultado de la Operación (Outcome)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TradeOutcome>(
                segments: const [
                  ButtonSegment(
                    value: TradeOutcome.pending,
                    label: Text('PENDING'),
                    icon: Icon(Icons.hourglass_empty_rounded),
                  ),
                  ButtonSegment(
                    value: TradeOutcome.won,
                    label: Text('WIN'),
                    icon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  ButtonSegment(
                    value: TradeOutcome.lost,
                    label: Text('LOSS'),
                    icon: Icon(Icons.highlight_off_rounded),
                  ),
                ],
                selected: {_selectedOutcome},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedOutcome = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      switch (_selectedOutcome) {
                        case TradeOutcome.won:
                          return AppTheme.winColor.withValues(alpha: 0.3);
                        case TradeOutcome.lost:
                          return AppTheme.lossColor.withValues(alpha: 0.3);
                        case TradeOutcome.pending:
                          return AppTheme.pendingColor.withValues(alpha: 0.3);
                      }
                    }
                    return AppTheme.cardColor;
                  }),
                ),
              ),
              const SizedBox(height: 36),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveForm,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    _isEditing ? 'Guardar Cambios' : 'Registrar Trade',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imageStr) {
    if (imageStr.startsWith('data:image') || !imageStr.startsWith('http')) {
      try {
        final base64Content = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image_rounded, size: 40));
      }
    }
    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
    );
  }
}
