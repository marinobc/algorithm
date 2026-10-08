import 'package:flutter/material.dart';

class GraphApplicationsSection extends StatelessWidget {
  const GraphApplicationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final applications = [
      (
        'Mapas y transporte',
        'Las ciudades son nodos y las carreteras son aristas con distancia o tiempo.',
        Icons.map_outlined,
      ),
      (
        'Internet',
        'Los dispositivos y servidores se conectan para enviar información por distintas rutas.',
        Icons.language_rounded,
      ),
      (
        'Recomendaciones',
        'Las relaciones entre usuarios, productos o contenidos ayudan a encontrar opciones relevantes.',
        Icons.recommend_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOS GRAFOS EN LA VIDA REAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Una misma idea, muchas aplicaciones',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800
                ? 3
                : constraints.maxWidth >= 500
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applications.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 156,
              ),
              itemBuilder: (context, index) {
                final application = applications[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        application.$3,
                        color: colorScheme.secondary,
                        size: 26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        application.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Text(
                          application.$2,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
