import 'package:flutter/material.dart';

import '../../domain/models/atributo.dart';
import '../text/app_text.dart';
import '../theme/app_theme.dart';

class DeleteAttributeDialog extends StatelessWidget {
  final Atributo attr;
  final String valuesSummary;

  const DeleteAttributeDialog({
    super.key,
    required this.attr,
    required this.valuesSummary,
  });

  static Future<bool?> show(
    BuildContext context,
    Atributo attr,
    String valuesSummary,
  ) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) =>
          DeleteAttributeDialog(attr: attr, valuesSummary: valuesSummary),
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
              '¿Eliminar atributo "${attr.nombre}"?',
              style: TextStyle(
                color: palette.alertColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estas borrando los siguientes valores seguro:',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.canvasBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valuesSummary,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
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
                      color: palette.alertColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: NeumorphicShadows.inset(
                        palette,
                        distance: 2,
                        blur: 4,
                      ),
                    ),
                    child: const Text(
                      AppText.delete,
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
