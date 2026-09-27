import 'package:flutter/material.dart';

import '../../../../algorithms/johnson/ui/johnson_launch_button.dart';

class JohnsonHeroSection extends StatelessWidget {
  const JohnsonHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00BFA5).withValues(alpha: 0.25),
            colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 36.0,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 16,
                          color: Color(0xFF00BFA5),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tiempos de Ida y Regreso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00BFA5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Algoritmo de Johnson',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 42 : 30,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Text(
                      'Un método intuitivo para calcular tiempos tempranos y tardíos en proyectos. ¡De ida sumamos los máximos y de regreso restamos los mínimos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width > 700 ? 18 : 15,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const JohnsonLaunchButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
