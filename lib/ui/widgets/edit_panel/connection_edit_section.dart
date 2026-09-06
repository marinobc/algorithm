import 'package:flutter/material.dart';
import '../../../domain/models/direccion.dart';
import '../../text/connection_text.dart';

/// Single Responsibility component for Connection property editing (Direction choice & Self-Loop angle).
class ConnectionEditSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isSelfLoop;
  final Direccion selectedDireccion;
  final String currentDirectionOptionId;
  final List<ChoiceChipOption> directionOptions;
  final double loopAngle;
  final ValueChanged<double>? onLoopAngleChanged;

  const ConnectionEditSection({
    super.key,
    required this.colorScheme,
    required this.isSelfLoop,
    required this.selectedDireccion,
    required this.currentDirectionOptionId,
    required this.directionOptions,
    this.loopAngle = 0.0,
    this.onLoopAngleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSelfLoop) ...[
          const SizedBox(height: 16),
          Text(
            ConnectionText.selectConnectionDirection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            children: directionOptions.map((opt) {
              final isSelected = opt.id == currentDirectionOptionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  onTap: opt.onSelect,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class ChoiceChipOption {
  final String id;
  final String label;
  final VoidCallback onSelect;

  const ChoiceChipOption({
    required this.id,
    required this.label,
    required this.onSelect,
  });
}
