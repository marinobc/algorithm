import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/config_provider.dart';
import '../../domain/models/direccion.dart';
import '../theme/app_theme.dart';

typedef ConfigDialog = ConfigScreen;

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  late TextEditingController _valController;
  late ThemeMode _selectedTheme;
  late Direccion _selectedConnType;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(configProvider);
    _valController = TextEditingController(
      text: currentConfig.valorConexionPorDefecto,
    );
    _selectedTheme = currentConfig.themeMode;
    _selectedConnType = currentConfig.tipoConexionPorDefecto;
  }

  @override
  void dispose() {
    _valController.dispose();
    super.dispose();
  }

  void _autoSaveConfig() {
    String val = _valController.text.trim();
    final parsed = double.tryParse(val);
    if (val.isEmpty || parsed == null || parsed <= 0) {
      val = '1';
    }
    final notifier = ref.read(configProvider.notifier);
    notifier.setValorConexionPorDefecto(val);
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
                            title: 'Conexión Dirigida (Flecha Origen ➔ Destino)',
                            subtitle: 'Asigna dirección unidireccional por defecto',
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

                  // Section 2: Default Connection Weight Card (User Input Only)
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
                                Icons.numbers,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Valor Inicial para Conexiones',
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
                          TextField(
                            controller: _valController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            onChanged: (_) => _autoSaveConfig(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              labelText: 'Valor numérico inicial de la arista',
                              hintText: 'Ej: 1, 10, 50',
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
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
                            subtitle: 'Fondo claro con acentos morados y violeta',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RadioOptionCard<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String? subtitle;
  final IconData icon;
  final ValueChanged<T> onSelected;

  const RadioOptionCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
