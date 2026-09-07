import 'package:flutter/material.dart';

import '../../text/dialog_text.dart';
import '../../theme/app_theme.dart';

/// Single Responsibility component for Node property editing (name, primary color swatches & custom Hex picker).
class NodeEditSection extends StatefulWidget {
  final TextEditingController nameController;
  final ColorScheme colorScheme;
  final NeumorphicPalette palette;
  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<String> onNameChanged;

  static const List<int> primarySwatches = [
    0xFF7C4DFF, // Electric Violet
    0xFF651FFF, // Deep Indigo
    0xFF00BFA5, // Vivid Emerald Teal
    0xFF00E676, // Bright Neon Mint
    0xFFFF1744, // Bright Crimson Coral
    0xFFFF5252, // Warm Coral
    0xFFFF9100, // Vivid Orange
    0xFFFFC400, // Golden Amber
    0xFFAEEA00, // Vivid Lime
    0xFF00E5FF, // Glowing Cyan
    0xFFD500F9, // Neon Magenta
    0xFFAA00FF, // Deep Violet
  ];

  const NodeEditSection({
    super.key,
    required this.nameController,
    required this.colorScheme,
    required this.palette,
    required this.selectedColorValue,
    required this.onColorSelected,
    required this.onNameChanged,
  });

  @override
  State<NodeEditSection> createState() => _NodeEditSectionState();
}

class _NodeEditSectionState extends State<NodeEditSection> {
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(
      text: _colorToHex(widget.selectedColorValue),
    );
  }

  @override
  void didUpdateWidget(covariant NodeEditSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColorValue != widget.selectedColorValue) {
      final newHex = _colorToHex(widget.selectedColorValue);
      if (_hexController.text.toUpperCase() != newHex) {
        _hexController.text = newHex;
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(int colorVal) {
    final color = Color(colorVal);
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  void _onHexChanged(String text) {
    String clean = text.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) {
        widget.onColorSelected(val);
      }
    } else if (clean.length == 8) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        widget.onColorSelected(val);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final selectedColor = Color(widget.selectedColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: widget.nameController,
          onChanged: widget.onNameChanged,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            labelText: DialogText.nodeName,
            labelStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Primary Color Swatches Header
        Text(
          'Colores Primarios',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NodeEditSection.primarySwatches.map((colorVal) {
            final isSelected = widget.selectedColorValue == colorVal;
            return GestureDetector(
              onTap: () {
                widget.onColorSelected(colorVal);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(colorVal),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colorScheme.primary, width: 3)
                      : Border.all(color: Colors.transparent, width: 0),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(colorVal).withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Custom Hex Color Picker Input & Live Preview Box
        Text(
          'Color Personalizado (Código Hexadecimal)',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Live Color Preview Indicator Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.palette,
                  size: 20,
                  color: selectedColor.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hexController,
                onChanged: _onHexChanged,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'HEX e.g. #FF5722',
                  hintText: '#RRGGBB',
                  prefixIcon: const Icon(Icons.colorize_rounded, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
