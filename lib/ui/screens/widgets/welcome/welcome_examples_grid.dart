import 'package:flutter/material.dart';

class WelcomeExamplesGrid extends StatelessWidget {
  const WelcomeExamplesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 1;
    if (width >= 900) {
      crossAxisCount = 3;
    } else if (width >= 600) {
      crossAxisCount = 2;
    }

    final examples = [
      {
        'number': '01',
        'title': 'Navegación y Rutas GPS',
        'subtitle': 'Google Maps, Waze, Logística',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF00BFA5),
        'image': 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&auto=format&fit=crop',
        'description': 'Al solicitar una ruta en tu teléfono, un algoritmo analiza miles de calles, intersecciones y condiciones de tráfico en vivo para calcular en milisegundos el trayecto óptimo hasta tu destino.',
      },
      {
        'number': '02',
        'title': 'Búsqueda y Recomendaciones',
        'subtitle': 'Google, Spotify, Redes Sociales',
        'icon': Icons.manage_search_rounded,
        'color': const Color(0xFF7C4DFF),
        'image': 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=600&auto=format&fit=crop',
        'description': 'Cuando buscas información o escuchas música, los algoritmos examinan e indexan millones de datos para mostrarte de inmediato los resultados más relevantes según tu contexto e historial.',
      },
      {
        'number': '03',
        'title': 'Organización y Clasificación',
        'subtitle': 'Filtros, Precios, Catálogos',
        'icon': Icons.sort_rounded,
        'color': const Color(0xFFFF5252),
        'image': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600&auto=format&fit=crop',
        'description': 'Desde ordenar contactos o correos electrónicos por fecha hasta estructurar inventarios de tiendas electrónicas, los algoritmos de ordenamiento permiten priorizar datos velozmente.',
      },
    ];

    if (crossAxisCount == 1) {
      return Column(
        children: examples
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildExampleWebCard(context, e),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 520,
      ),
      itemCount: examples.length,
      itemBuilder: (context, index) {
        return _buildExampleWebCard(context, examples[index]);
      },
    );
  }

  Widget _buildExampleWebCard(BuildContext context, Map<String, dynamic> data) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = data['color'] as Color;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['image'] != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                data['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: accentColor.withValues(alpha: 0.2)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            data['icon'] as IconData,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        Text(
                          data['number'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data['title'] as String,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
