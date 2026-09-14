import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/grafo_provider.dart';
import '../providers/johnson_provider.dart';

/// Floating canvas toolbar displayed specifically when the Johnson Algorithm
/// mode is active. Shows DAG status, activity count, and real-time validity.
class JohnsonCanvasControls extends ConsumerWidget {
  const JohnsonCanvasControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validation = ref.watch(johnsonValidationProvider);
    final grafo = ref.watch(grafoProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF00BFA5);

    final nodeCount = grafo.nodos.length;
    final edgeCount = grafo.conexiones.length;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alt_route_rounded, color: accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Modo Johnson (DAG):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$nodeCount nodos • $edgeCount aristas',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            if (validation.isValid) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
