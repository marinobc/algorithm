import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../theme/app_theme.dart';

/// Modal dialog shown when a connection being edited duplicates an existing
/// connection between the same pair of nodes.
class ConnectionDuplicateDialog extends StatelessWidget {
  final String origName;
  final String destName;

  const ConnectionDuplicateDialog({
    super.key,
    required this.origName,
    required this.destName,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String origName,
    required String destName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConnectionDuplicateDialog(
        origName: origName,
        destName: destName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeumorphicPalette.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surfaceBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: palette.darkShadow.withValues(alpha: 0.15),
            width: 1.0,
          ),
          boxShadow: NeumorphicShadows.dialog(palette),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conexión existente',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ya existe una conexión en esa dirección ($origName ➔ $destName). ¿Deseas reemplazarla o cancelar?',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    AppText.cancel,
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primaryAccent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: NeumorphicShadows.inset(
                        palette,
                        distance: 2,
                        blur: 4,
                      ),
                    ),
                    child: const Text(
                      'Reemplazar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
