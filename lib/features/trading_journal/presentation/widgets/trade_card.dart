import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/trade.dart';

/// Widget de tarjeta individual para listar los Trades en el historial.
class TradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TradeCard({
    super.key,
    required this.trade,
    required this.onTap,
    required this.onDelete,
  });

  Color _getOutcomeColor(TradeOutcome outcome) {
    switch (outcome) {
      case TradeOutcome.won:
        return AppTheme.winColor;
      case TradeOutcome.lost:
        return AppTheme.lossColor;
      case TradeOutcome.pending:
        return AppTheme.pendingColor;
    }
  }

  IconData _getOutcomeIcon(TradeOutcome outcome) {
    switch (outcome) {
      case TradeOutcome.won:
        return Icons.trending_up_rounded;
      case TradeOutcome.lost:
        return Icons.trending_down_rounded;
      case TradeOutcome.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  void _showImageModal(BuildContext context, String imageStr) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageWidget(imageStr, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageStr, {BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('data:image') || !imageStr.startsWith('http')) {
      try {
        final base64Content = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary),
        );
      } catch (_) {
        return const Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary);
      }
    }
    return Image.network(
      imageStr,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcomeColor = _getOutcomeColor(trade.outcome);
    final formattedDate = DateFormat('dd MMM yyyy').format(trade.entryDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Indicador visual lateral con el resultado
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: outcomeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: outcomeColor, width: 1.5),
                    ),
                    child: Icon(
                      _getOutcomeIcon(trade.outcome),
                      color: outcomeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información del Trade
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              trade.asset,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                trade.strategy,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${trade.session.icon} ${trade.session.label}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.balance_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'R:R 1:${trade.riskRewardRatio.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (trade.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sticky_note_2_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trade.notes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Badge de resultado y botón eliminar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: outcomeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trade.outcome.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: outcomeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Eliminar trade',
                      ),
                    ],
                  ),
                ],
              ),

              // Thumbnail de la captura del gráfico si existe
              if (trade.imageUrl != null && trade.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showImageModal(context, trade.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: AppTheme.cardColor,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: _buildImageWidget(trade.imageUrl!),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Ver Chart Completo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
