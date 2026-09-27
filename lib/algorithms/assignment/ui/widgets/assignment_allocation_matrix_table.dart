import 'package:flutter/material.dart';

import '../../domain/models/assignment_models.dart';

class AssignmentAllocationMatrixTable extends StatelessWidget {
  final TransportationResult result;
  final TransportationProblemData problem;

  const AssignmentAllocationMatrixTable({
    super.key,
    required this.result,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matriz Final de Asignaciones Óptimas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: _buildAllocationMatrixTable(colorScheme),
        ),
        const SizedBox(height: 24),
        Text(
          'Desglose de Pares Asignados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _buildAssignmentChips(colorScheme),
        ),
      ],
    );
  }

  Widget _buildAllocationMatrixTable(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Origen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...result.destinationLabels.map((dest) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          dest,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              ...List.generate(result.originLabels.length, (i) {
                final origName = result.originLabels[i];
                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        origName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...List.generate(result.destinationLabels.length, (j) {
                      final alloc = result.allocationMatrix[i][j];
                      final isAssigned = alloc > 0;
                      final cost = result.costMatrix[i][j];
                      final costText = cost.isFinite && cost < 1e5
                          ? cost
                                .toStringAsFixed(1)
                                .replaceAll(RegExp(r'\.0$'), '')
                          : '∞';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        color: isAssigned
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.55,
                              )
                            : colorScheme.surfaceContainerLow.withValues(
                                alpha: 0.3,
                              ),
                        child: Text(
                          isAssigned ? '1 (c=$costText)' : '0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isAssigned
                                ? FontWeight.w800
                                : FontWeight.normal,
                            color: isAssigned
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAssignmentChips(ColorScheme colorScheme) {
    final chips = <Widget>[];

    for (int i = 0; i < result.allocationMatrix.length; i++) {
      for (int j = 0; j < result.allocationMatrix[i].length; j++) {
        if (result.allocationMatrix[i][j] > 0) {
          if (i >= problem.origins.length || j >= problem.destinations.length) {
            continue;
          }
          final origLabel = result.originLabels[i];
          final destLabel = result.destinationLabels[j];
          final cost = result.costMatrix[i][j];
          final displayCost = cost.isFinite && cost < 1e5
              ? cost.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
              : '0';

          chips.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.check, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$origLabel ➔ $destLabel (Costo: $displayCost)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return chips;
  }
}
