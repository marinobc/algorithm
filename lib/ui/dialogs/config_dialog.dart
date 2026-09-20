import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/config_provider.dart';
import '../../domain/models/direccion.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_option_card.dart';

typedef ConfigDialog = ConfigScreen;

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  late ThemeMode _selectedTheme;
  late Direccion _selectedConnType;
  late bool _mostrarDebug;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(configProvider);
    _selectedTheme = currentConfig.themeMode;
    _selectedConnType = currentConfig.tipoConexionPorDefecto;
    _mostrarDebug = currentConfig.mostrarBotonesDebug;
  }

  void _autoSaveConfig() {
    final notifier = ref.read(configProvider.notifier);
    notifier.setTipoConexionPorDefecto(_selectedConnType);
    notifier.setThemeMode(_selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = NeumorphicPalette.of(context);

    return Scaffold(
      backgroundColor: palette.canvasBg,
      appBar: AppBar(
        title: const Text('Configuración del Sistema'),
        centerTitle: false,
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () {
            _autoSaveConfig();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Default Connection Direction Radius Selection Cards
                  Card(
                    elevation: 1,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.alt_route_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Dirección de Conexión por Defecto',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RadioOptionCard<Direccion>(
                            value: Direccion.unidireccional,
                            groupValue: _selectedConnType,
                            title: 'Conexión Dirigida (Origen -> Destino)',
                            subtitle:
                                'Asigna dirección unidireccional por defecto',
                            icon: Icons.arrow_forward_rounded,
                            onSelected: (val) {
                              setState(() => _selectedConnType = val);
                              _autoSaveConfig();
                            },
                          ),
                          RadioOptionCard<Direccion>(
                            value: Direccion.ninguna,
                            groupValue: _selectedConnType,
                            title: 'Conexión No Dirigida (Línea Simple)',
                            subtitle: 'Asigna líneas simples sin orientación',
                            icon: Icons.horizontal_rule_rounded,
                            onSelected: (val) {
                              setState(() => _selectedConnType = val);
                              _autoSaveConfig();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Visual Theme Radius Selection Cards
                  Card(
                    elevation: 1,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tema Visual del Sistema',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RadioOptionCard<ThemeMode>(
                            value: ThemeMode.system,
                            groupValue: _selectedTheme,
                            title: 'Automático / Sistema',
                            subtitle: 'Adapta automáticamente al tema del dispositivo',
                            icon: Icons.brightness_auto_rounded,
                            onSelected: (val) {
                              setState(() => _selectedTheme = val);
                              _autoSaveConfig();
                            },
                          ),
                          RadioOptionCard<ThemeMode>(
                            value: ThemeMode.light,
                            groupValue: _selectedTheme,
                            title: 'Tema Claro',
                            subtitle:
                                'Fondo claro con acentos morados y violeta',
                            icon: Icons.wb_sunny_outlined,
                            onSelected: (val) {
                              setState(() => _selectedTheme = val);
                              _autoSaveConfig();
                            },
                          ),
                          RadioOptionCard<ThemeMode>(
                            value: ThemeMode.dark,
                            groupValue: _selectedTheme,
                            title: 'Tema Oscuro',
                            subtitle: 'Fondo oscuro profundo de alto contraste',
                            icon: Icons.dark_mode_outlined,
                            onSelected: (val) {
                              setState(() => _selectedTheme = val);
                              _autoSaveConfig();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Developer Tools Toggle
                  Card(
                    elevation: 1,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.bug_report_outlined,
                          color: _mostrarDebug
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        title: const Text(
                          'Botones de Debug',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Muestra los botones de copiar/pegar grafo en el editor',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _mostrarDebug,
                        onChanged: (val) {
                          setState(() => _mostrarDebug = val);
                          ref
                              .read(configProvider.notifier)
                              .setMostrarBotonesDebug(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
