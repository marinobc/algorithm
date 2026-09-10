import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/atributo.dart';
import '../../text/connection_text.dart';
import '../../theme/app_theme.dart';

class CustomAttributesSection extends StatelessWidget {
  final List<Atributo> atributosGlobales;
  final ColorScheme colorScheme;
  final NeumorphicPalette palette;
  final TextEditingController newAttrController;
  final TextEditingController Function(String attrId) getAttrController;
  final TextEditingController Function(String attrId, String currentName)
  getAttrTagNameController;
  final void Function(String attrId, String newTag) onTagRenamed;
  final VoidCallback onValueChanged;
  final void Function(Atributo attr) onDeleteAttribute;
  final VoidCallback onAddAttribute;

  const CustomAttributesSection({
    super.key,
    required this.atributosGlobales,
    required this.colorScheme,
    required this.palette,
    required this.newAttrController,
    required this.getAttrController,
    required this.getAttrTagNameController,
    required this.onTagRenamed,
    required this.onValueChanged,
    required this.onDeleteAttribute,
    required this.onAddAttribute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          ConnectionText.attributesHeader,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final attr in atributosGlobales) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: _buildTextField(
                    controller: getAttrTagNameController(attr.id, attr.nombre),
                    label: 'Etiqueta',
                    colorScheme: colorScheme,
                    onChanged: (newTag) {
                      final trimmed = newTag.trim();
                      if (trimmed.isNotEmpty) {
                        onTagRenamed(attr.id, trimmed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: getAttrController(attr.id),
                    label: 'Valor',
                    colorScheme: colorScheme,
                    isNumeric: true,
                    onChanged: (_) => onValueChanged(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () => onDeleteAttribute(attr),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: newAttrController,
                label: ConnectionText.attributeName,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddAttribute,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ColorScheme colorScheme,
    ValueChanged<String>? onChanged,
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      onChanged: onChanged,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }
}
